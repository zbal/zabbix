Zabbix custom monitoring
========================

This is a collection of custom scripts developed over time to monitor the essential services of a LAMP stack :

* Web servers; Apache, Nginx
* Databases; MySQL
* Caching servers; Varnish, Memcached
* File system; iostat, vmstat, column-reader, log-match

Contact
=======

All updates / forks / suggestions are more than welcome!
  vincent.viallet@gmail.com

Credits
=======

* ChinaNetCloud; they made me discover Zabbix and I developed a huge amount of custom scripts for them
* Wiredcraft; they made me re-think and review most of my scripts and jump to another level

Usage
=====

(Almost) one liner install script, as root...

<code>curl -k https://raw.github.com/zbal/zabbix/master/setup/setup.sh > zabbix_setup.sh && bash zabbix_setup.sh</code>

Requirements
============

* Zabbix agent need to be installed
* Sudo need to be installed
* Web servers need to get their server-status equivalent set
* probably more - please notify me if some requirements are missing...

Changes on the server
=====================

Since some files are unreadable to the zabbix user, some extra permissions are needed and require changes in the sudo configuration.

Zabbix need to be able to run via sudo :

* cat; to read some innodb status file (mysql),
* tail; to read some log files (log-match),
* test; perform .. some tests on files (log-match, column-reader),
* stat; to see some file status change (log-match).

More will probably be added as the needs appears (ex. iptables monitoring, etc.)

Platform
========

The script collection should be working for Ubuntu / Debian / CentOS / RedHat. (Debian-like system have not been thoroughly tested so far). 