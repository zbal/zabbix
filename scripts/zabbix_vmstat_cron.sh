#!/bin/bash
##################################
# Zabbix monitoring script
#
# Info:
#  - cron job to gather vmstat data
#  - can not do real time as vmstat data gathering will exceed 
#    Zabbix agent timeout
##################################
# Contact:
#  vincent.viallet@gmail.com
##################################
# ChangeLog:
#  20100922	VV	initial creation
##################################

# source data file
DEST_DATA=/usr/share/zabbix/data/zabbix_vmstat
TMP_DATA=/usr/share/zabbix/data/zabbix_vmstat.tmp

#
# gather data in temp file first, then move to final location
# it avoids zabbix-agent to gather data from a half written source file
#
# vmstat 10 2 - will display 2 lines :
#  - 1st: statistics since boot -- useless
#  - 2nd: statistics over the last 10 sec
#
vmstat 10 2 > $TMP_DATA
mv $TMP_DATA $DEST_DATA


