#!/bin/bash -x

IPList=/usr/local/bin/Netshield/NetshieldIP.txt    #TextFile containing IP's to poll

#count rows in iplist
rows=$(wc -l /usr/local/bin/Netshield/NetshieldIP.txt |awk '{print $1}')

#Fetch the IP and SNMPv3 credentials to a ARRAY
nr=1
while [ $nr -le $rows ]
do

y=$(sed -n $nr\p < $IPList;)
IFS=',' read -r -a array <<< $y
IP=${array[0]}
USER=${array[1]}
PW=${array[2]}
PW2=${array[3]}

DB=($(echo ${array[0]} | tr '.' '_'))
DB_Sys="$DB"_Sys
DB_Ifs="$DB"_Ifs
DB_Ifs_stats="$DB"_Ifs_stats
DB_Rules="$DB"_Rules

	Ifs_Name=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.3.2.2010.3010.1.2 | awk '{print $4}')
	Ifs_Stat_in1=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1030 | awk '{print $4}')
	Ifs_Stat_out1=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1033 | awk '{print $4}')
	
	#Sleep for 10 Sec to calculate speed
	sleep 10
	
	Ifs_Stat_in2=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1030 | awk '{print $4}')
	Ifs_Stat_out2=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1033 | awk '{print $4}')
	
	#Ifs to ARRAY	
	Ifs_Name_A=($(echo $Ifs_Name | tr '"' '\n'))
	Ifs_Stat_in_A1=($(echo $Ifs_Stat_in1 | tr ' ' '\n'))
	Ifs_Stat_in_A2=($(echo $Ifs_Stat_in2 | tr ' ' '\n'))
	Ifs_Stat_out_A1=($(echo $Ifs_Stat_out1 | tr ' ' '\n'))
	Ifs_Stat_out_A2=($(echo $Ifs_Stat_out2 | tr ' ' '\n'))
	nr_ifs=${#Ifs_Name_A[@]}

	Ifs_packet_rec=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1030 | awk '{print $4}')

	#Create DB
	curl -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE \"$DB_Sys\""
	curl -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE \"$DB_Ifs\""
	curl -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE \"$DB_Ifs_stats\""
        curl -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE \"$DB_Rules\""

	Ifs_packet_rec=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1059 | awk '{print $4}')
	Ifs_packet_rec_A=($(echo $Ifs_packet_rec | tr '"' '\n'))
	nr4=${#Ifs_packet_rec_A[@]}
	Ifs_packet_sent=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1059 | awk '{print $4}')
        Ifs_packet_rsent_A=($(echo $Ifs_packet_rec | tr '"' '\n'))
        nr5=${#Ifs_packet_sent_A[@]}
	Ifs_packet_dropped=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2010.3010.1.1056 | awk '{print $4}')
        Ifs_packet_dropped_A=($(echo $Ifs_packet_rec | tr '"' '\n'))
        nr6=${#Ifs_packet_dropped_A[@]}

	for (( i=0; i<$nr4; i++ ))
	do
		        curl -i -XPOST "http://localhost:8086/write?db=$DB_Ifs_stats" --data-binary "HW=${Ifs_Name_A[$i]}"_rec",host=$IP value=${Ifs_packet_rec_A[$i]}"
	done

	for (( i=0; i<$nr5; i++ ))
		do
			curl -i -XPOST "http://localhost:8086/write?db=$DB_Ifs_stats" --data-binary "HW=${Ifs_Name_A[$i]}"_sent",host=$IP value=${Ifs_packet_sent_A[$i]}"
	done

	for (( i=0; i<$nr4; i++ ))
		do
			curl -i -XPOST "http://localhost:8086/write?db=$DB_Ifs_stats" --data-binary "HW=${Ifs_Name_A[$i]}"_dropped",host=$IP value=${Ifs_packet_dropped_A[$i]}"
	done

	for (( i=0; i<$nr_ifs; i++ ))
		do
			# Calculate In BW
			Ifs_Stat_A3_1=$(expr ${Ifs_Stat_in_A2[$i]} - ${Ifs_Stat_in_A1[$i]})
			Ifs_Stat_A3=$(echo "scale = 2; $Ifs_Stat_A3_1 / 10" |bc)
			Ifs_Stat_A4=$(echo "scale = 2; $Ifs_Stat_A3 / 1000 / 1000 *8" |bc )
			
			# Calculate Out BW
			Ifs_Stat_A5_1=$(expr ${Ifs_Stat_out_A2[$i]} - ${Ifs_Stat_out_A1[$i]})
			Ifs_Stat_A5=$(echo "scale = 2; $Ifs_Stat_A5_1 / 10" | bc)
			Ifs_Stat_A6=$(echo "scale = 2; $Ifs_Stat_A5 / 1000 / 1000 *8" |bc )
			
			# check for wrapping of counters
			if [ $(( ${Ifs_Stat_A4%.*} )) -lt 0 ]
			then
				Ifs_Stat_A4=0
			fi
			if [ $(( ${Ifs_Stat_A6%.*} )) -lt 0 ]
			then
				Ifs_Stat_A6=0
			fi
			
			#Post to InfluxDB
			curl -i -XPOST "http://localhost:8086/write?db=$DB_Ifs" --data-binary "${Ifs_Name_A[$i]},host=$IP,Direction=In value=$Ifs_Stat_A4"
			curl -i -XPOST "http://localhost:8086/write?db=$DB_Ifs" --data-binary "${Ifs_Name_A[$i]},host=$IP,Direction=Out value=$Ifs_Stat_A6"

	       done

	#Rules usage
        Rule_Name=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.3.2.2070.2010.1.2 | awk '{print $4}')
        Rule_Hit=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.3.2.2070.2010.1.1010 | awk '{print $4}')
        
	#Rules to ARRAY
        Rule_Name_A=($(echo $Rule_Name | tr '"' '\n'))
        Rule_Hit_A=($(echo $Rule_Hit | tr '"' '\n'))
	nr1=${#Rule_Name_A[@]}
	for (( i=0; i<$nr1; i++ ))
	do
		curl -i -XPOST "http://localhost:8086/write?db=$DB_Rules" --data-binary "Rule=${Rule_Name_A[$i]},host=$IP value=${Rule_Hit_A[$i]}"
	done

# Sleep for 3 sec to get a more true CPU value
sleep 3
CPU_name=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP iso.3.6.1.4.1.5089.3.2.2005.2020.3000.1.2 | awk '{print $4}')
CPU_usage=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP iso.3.6.1.4.1.5089.3.2.2005.2020.3000.1.1010 | awk '{print $4}')
CPU_name_A=($(echo $CPU_name | tr '"' '\n'))
CPU_usage_A=($(echo $CPU_usage | tr '"' '\n'))
nr2=${#CPU_name_A[@]}
for (( i=0; i<$nr2; i++ ))
do
	curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "CPU=${CPU_name_A[$i]},host=$IP value=${CPU_usage_A[$i]}"
done

HW_mon_name=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2050.2030.3040.1.2 | awk '{print $4,$5,$6}' | tr -s ' ' '_')
HW_mon_value=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2050.2030.3040.1.1010 | awk '{print $4}')
HW_mon_name_A=($(echo $HW_mon_name | tr '"' '\n'))
HW_mon_value_A=($(echo $HW_mon_value | tr '"' '\n'))
nr3=${#HW_mon_name_A[@]}
for (( i=0; i<$nr3; i++ ))
do
	curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "HW=${HW_mon_name_A[$i]},host=$IP value=${HW_mon_value_A[$i]}"
done

#High Availability
HA_Failover=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2005.2040.1050.0 | awk '{print $4}')
HA_Unsynced=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2005.2040.1065.0 | awk '{print $4}')
HA_Synclevel=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2005.2040.1060.0 | awk '{print $4}')
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "HA_failover,host=$IP value=$HA_Failover"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "HA_Unsynced,host=$IP value=$HA_Unsynced"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "HA_Synclevel,host=$IP value=$Ha_Synclevel"

#Flows
Flows=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.3.2.2005.2010.1005.0 | awk '{print $4}')
Flow_limit=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.3.2.2005.2010.1010.0 | awk '{print $4}')
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Flows,host=$IP value=$Flows"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Flow_limit,host=$IP value=$Flow_limit"

#Authentication
Brute_force=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2030.2010.1050.0 | awk '{print $4}')
Auth_failed=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2030.2010.1020.0 | awk '{print $4}')
Auth_rejected=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2030.2010.1025.0 | awk '{print $4}')
Auth_started=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2030.2010.1030.0 | awk '{print $4}')
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Brute_force,host=$IP value=$Brute_force"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Auth_failed,host=$IP value=$Auth_failed"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Auth_rejected,host=$IP value=$Auth_rejected"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Auth_started,host=$IP value=$Auth_started"

#BGP

#Memmory
Ctrl_mem_used=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2005.2030.1005.0 | awk '{print $4}')
Data_mem_used=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2005.2030.1020.0 | awk '{print $4}')
Ctrl_mem_free=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2005.2030.1010.0 | awk '{print $4}')
Data_mem_free=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2005.2030.1025.0 | awk '{print $4}')
Ctrl_mem_tot=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2005.2030.1015.0 | awk '{print $4}')
Data_mem_tot=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.3.2.2005.2030.1030.0 | awk '{print $4}')
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Ctrl_mem_used,host=$IP value=$Ctrl_mem_used"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Data_mem_used,host=$IP value=$Data_mem_used"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Ctrl_mem_free,host=$IP value=$Ctrl_mem_free"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Data_mem_free,host=$IP value=$Data_mem_free"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Ctrl_mem_tot,host=$IP value=$Ctrl_mem_tot"
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Data_mem_tot,host=$IP value=$Data_mem_tot"

NTP_status=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.4.1.5089.3.2.2080.2090.1075.0 | awk '{print $4}')
Uptime=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.2.1.1.3.0 |awk '{print $5}' | tr -d ,)
Sys_name=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.2.1.1.1.0 | awk '{print $5,$6,$7,$8}' | tr '"' '\n')
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "NTP,host=$IP value="$NTP_status""
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Uptime1,host=$IP value="$Uptime""
curl -i -XPOST "http://localhost:8086/write?db=$DB_Sys" --data-binary "Sys_name,host=$IP value=\"$Sys_name\""
nr=$(( $nr + 1 ))
done
