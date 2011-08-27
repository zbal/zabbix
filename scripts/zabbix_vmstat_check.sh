#!/bin/bash
##################################
# Zabbix monitoring script
#
# vmstat:
#  - IO
#  - running / blocked processes
#  - swap in / out
#  - block in / out
#
# Info:
#  - vmstat data are gathered via cron job
#  - soon OUTDATED - can use mostly system.stat[resource,<type>] from 
#    Zabbix-1.8.1 - need to update Template
##################################
# Contact:
#  vincent.viallet@gmail.com
##################################
# ChangeLog:
#  20100922	VV	initial creation
##################################

# Zabbix requested parameter
ZBX_REQ_DATA="$1"

# source data file
SOURCE_DATA=/usr/share/zabbix/data/zabbix_vmstat

#
# Error handling:
#  - need to be displayable in Zabbix (avoid NOT_SUPPORTED)
#  - items need to be of type "float" (allow negative + float)
#
ERROR_NO_DATA_FILE="-0.9900"
ERROR_OLD_DATA="-0.9901"
ERROR_WRONG_PARAM="-0.9902"

if [ ! -f "$SOURCE_DATA" ]; then
  echo $ERROR_NO_DATA_FILE
  exit 1
fi

#
# Old data handling:
#  - in case the cron can not update the data file
#  - in case the data are too old we want to notify the system
# Consider the data as non-valid if older than OLD_DATA minutes
#
OLD_DATA=5
if [ $(stat -c "%Y" $SOURCE_DATA) -lt $(date -d "now -$OLD_DATA min" "+%s" ) ]; then
  echo $ERROR_OLD_DATA
  exit 1
fi

# 
# Grab data from SOURCE_DATA for key ZBX_REQ_DATA
#
case $ZBX_REQ_DATA in
  r)     tail -1 $SOURCE_DATA | awk '{print $1}';;
  b)     tail -1 $SOURCE_DATA | awk '{print $2}';;
  swpd)  tail -1 $SOURCE_DATA | awk '{print $3}';;
  free)  tail -1 $SOURCE_DATA | awk '{print $4}';;
  buff)  tail -1 $SOURCE_DATA | awk '{print $5}';;
  cache) tail -1 $SOURCE_DATA | awk '{print $6}';;
  si)    tail -1 $SOURCE_DATA | awk '{print $7}';;
  so)    tail -1 $SOURCE_DATA | awk '{print $8}';;
  bi)    tail -1 $SOURCE_DATA | awk '{print $9}';;
  bo)    tail -1 $SOURCE_DATA | awk '{print $10}';;
  in)    tail -1 $SOURCE_DATA | awk '{print $11}';;
  cs)    tail -1 $SOURCE_DATA | awk '{print $12}';;
  us)    tail -1 $SOURCE_DATA | awk '{print $13}';;
  sy)    tail -1 $SOURCE_DATA | awk '{print $14}';;
  id)    tail -1 $SOURCE_DATA | awk '{print $15}';;
  wa)    tail -1 $SOURCE_DATA | awk '{print $16}';;
  *) echo $ERROR_WRONG_PARAM; exit 1;;
esac

exit 0

