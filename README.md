# Clavister Netshield SNMP values to Influx

Graph SNMPv3 values from Clavister Netshield

## Description

This script uses crontab to set the polling intervall of the Netshield devices,
it will take the values and store them in InfluxDB. The values can then be used to 
make graphs in grafana.
Example dashboard (https://github.com/Foxmaster-stuff/Netshield-influxdb/blob/master/Example_Dashboard_Report.pdf) generated with grafana reporter.

## Getting Started

### Dependencies

* Setup uses Ubuntu server
* Grafana 11.2.2 (for ploting the values)
* InfluxDB (influxdb database)
* Influxdb-client (influx-client for manual editing of influxdb)
* SNMP (snmp for retriving the values)
* bc (bc for calculating the througput)
* Parallel (for "multithreading")
* apt install grafana=11.2.2 influxdb influxdb-client snmp bc parallel -y

### Installing

* The file NetshieldIP.txt is where the script reads IP,USER,SNMPv3-PW,USER-PW,

Example
```
192.168.105.3,apa,apa123456789,dt12576!,
```
* sudo systemctl enable influxdb
* sudo systemctl status influxdb
* sudo systemctl enable grafana-server.service
* sudo systemctl status grafana-server

### Executing program

* Script needs to be deployed in /usr/local/bin/Netshield/
* This script uses crontab to execute the script
Polls the network device every 5 min
```
*/5 * * * *     /usr/local/bin/Netshield/Main.sh > /dev/null 2>&1
```

## Help

Any advise for common problems or issues.
```
command to run if program contains helper info
```

## Authors

Contributors names and contact info

[Foxmaster](pemi@clavister.com)  

## Version History
* 0.4
    * Added Main.sh that uses parallel to spawn 1 process per line item in NetshieldIP.txt
      and 1 process per CPU core available (can be limited by using --job <number>)
* 0.3
    * Added databases to take advantage of Grafanas variable function
    * Databases will be prefixed with the IP of the target
    * There are now 4 influx databases IP_sys, IP_Ifs, IP_stats and IP_rules 
* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## License

This project is licensed under the BSD License - see the LICENSE.md file for details

## Recommended plugins

* [Grafana Reporter](https://github.com/mahendrapaipuri/grafana-dashboard-reporter-app)

## Acknowledgments

Inspiration, code snippets, etc.
* [Grafana](https://grafana.com/)
