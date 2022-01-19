# Project Title

Graph SNMP v3 values from Clavister Netshield

## Description

This script uses crontab to set the polling intervall of the Netshield devices,
it will take the values and store them in InfluxDB. The values can then be used to 
make graphs in grafana.

## Getting Started

### Dependencies

* In my setup I use Ubuntu server 20.04
* Grafana (apt install grafana)
* InfluxDB (apt install influxdb)
* Influx-client (apt install influx-client)

### Installing

* How/where to download your program
* Any modifications needed to be made to files/folders

### Executing program

* This script uses crontab to execute the script
* Step-by-step bullets
Polls the network device every 5 min
```
*/5 * * * *     /usr/local/bin/Netshield/Influx_Netshield.sh > /dev/null 2>&1
```

## Help

Any advise for common problems or issues.
```
command to run if program contains helper info
```

## Authors

Contributors names and contact info

ex. Dominique Pizzie  
ex. [@DomPizzie](https://twitter.com/dompizzie)

## Version History

* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [awesome-readme](https://github.com/matiassingers/awesome-readme)
* [PurpleBooth](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)
* [dbader](https://github.com/dbader/readme-template)
* [zenorocha](https://gist.github.com/zenorocha/4526327)
* [fvcproductions](https://gist.github.com/fvcproductions/1bfc2d4aecb01a834b46)
