# Zabbix custom monitoring

This is a collection of custom scripts developed over time to monitor the essential services of a LAMP stack:

* Web servers; Apache, Nginx
* Databases; MySQL
* Caching servers; Varnish, Memcached
* File system; iostat, vmstat, column-reader, log-match

# Contact

All updates / forks / suggestions are more than welcome!
*  vincent.viallet@gmail.com

# Credits

* [__ChinaNetCloud__](http://www.chinanetcloud.com); they made me discover Zabbix and I developed a huge amount of custom scripts for them
* [__Wiredcraft__](); they made me re-think and review most of my scripts and jump to another level

Objectives

# Usage

(Almost) one liner install script, as root...

<code>curl -k https://raw.github.com/zbal/zabbix/master/setup/setup.sh > zabbix_setup.sh && bash zabbix_setup.sh</code>

# Requirements

* Zabbix agent need to be installed,
* Sudo need to be installed,
* Web servers need to get their server-status equivalent set,
* Sysstat package need to be installed for iostat to work,
* probably more - please notify me if some requirements are missing...

# Changes on the server

Since some files are unreadable to the zabbix user, some extra permissions are needed and require changes in the sudo configuration.

Zabbix need to be able to run via sudo:

* cat; to read some innodb status file (mysql),
* tail; to read some log files (log-match),
* test; perform .. some tests on files (log-match, column-reader),
* stat; to see some file status change (log-match).

More will probably be added as the needs appears (ex. iptables monitoring, etc.)

# Platform

The script collection should be working for Ubuntu / Debian / CentOS / RedHat. (Debian-like system have not been thoroughly tested so far). 

# Custom scripts details

# Apache
Get data from server-status, extract relevant data from the scoreboard (need to be set properly)

## Nginx
Get data from server-status (need to be set properly)

## Memcached
Get data from memcachetool

## Varnish
Get data from varnishstat

## column-reader
Allows you to read any file and any column from it. Extremely useful to get data from /proc, /sys, other files which are providing column-base which are not world-readable.

## log-match
Allows you to match data in logs and give you counts based on REGEX. For instance, allows you to get count of return codes for 2xx, 3xx, 4xx, 5xx in web-logs, or anything kind of logs (varnish, etc.).

Further improvement is definitely required, more log format need to be supported...

## php-apc
Allows you to get the data out of the apc.php file.

One known issue is that apc.php is taking a fair amount of time to run, and might disrupt your webserver (especially if running with a limited amount of php workers). Think twice before using it! It might be interesting to see if a cron job is preferred.

## php-fpm
Allows you to get the data out of php-fpm status page. Mmmmh... I don't thnk I finished that script yet !

## iostat
Allows you to read data out of iostat. The zabbix agent is supposed (in the latest versions) to read the data through an embedded set of items, but ... for whatever reason, it was not working (and I didn't had the time to investigate).

It is working through a cron job, make sure you have sysstat installed...

Medium term, either zabbix built-in will be used, or another version (available partially already, see zabbix_iostat3_check.sh) to read the data out of /proc/diskstat instead.

## vmstat
Allows you to read the data out of the vmstat command. Probably available shortly via zabbix built-in.

Requires cron job to get the data.