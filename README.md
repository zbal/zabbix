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

* [__ChinaNetCloud__](http://www.chinanetcloud.com); they made me discover Zabbix and I developed a huge amount of custom scripts (so custom that it can't always be shared :)),
* [__Wiredcraft__](http://wiredcraft.com); they made me re-think, review and even entirely rewrite most of my scripts and jump to another level.

# Objectives

The closest we are from reality, the better we are. Real-time is strongly suggested in the development of those scripts.

Real-time might not always be the best approach due to latency to get data, cron jobs might be an alternative. But! most of the cronjobs behaviors can also be emulated through well thoughts scripts and temp files.

To make it simple, develop for real-time, do not worry about the amount of queries or commands required to get a result. If for whatever reason you hit an edge case where real-time is not an option, then work via temp files and finally cron jobs. And, I know, cron jobs and file parsing is usually easier to develop but think whenever you need to do mass deployment and perform changes on 200+ servers... Don't waste your time one deployment! Make you script platform agnostic and running with the least update you'd ever need!

# Usage

(Almost) one liner install script, as root...

<code>curl -k https://raw.github.com/zbal/zabbix/master/setup/setup.sh > zabbix_setup.sh && bash zabbix_setup.sh; rm -f zabbix_setup.sh</code>

(And yes, rm -f the script 'cause any existing zabbix_setup.sh file you may had has been overridden and is worth nothing anyway!)

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
Allows you to read any file and any column from it. Extremely useful to get data from /proc, /sys, other files which are providing column-based data which are not world-readable.

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

# Still not having Zabbix-agentd installed ??

Really ? C'mon it ain't that hard to find good binaries!

Try the following repo (CentOS / RH 5 only!):

cat >> /etc/yum.repos.d/zabbix.repo << EOF
[home_ericgearhart_zabbix]
name=Zabbix (RedHat_RHEL-5)
type=rpm-md
baseurl=http://download.opensuse.org/repositories/home:/ericgearhart:/zabbix/RedHat_RHEL-5/
gpgcheck=1
gpgkey=http://download.opensuse.org/repositories/home:/ericgearhart:/zabbix/RedHat_RHEL-5/repodata/repomd.xml.key
enabled=1
EOF

yum install -y zabbix-agent