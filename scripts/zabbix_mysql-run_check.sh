#!/bin/bash
##########################################
# MySQL real time query monitoring
# Allows to run predefined query and report the result
##########################################
# Contact :
#  vincent.viallet@chinanetcloud.com
##########################################

# Zabbix requested parameter - used as threshold for GOOD / BAD
ZBX_QUERY="$1"

# MySQL details
MYSQL_ACCESS="/usr/share/zabbix/conf/my.cnf"
MYSQL_BIN="/usr/bin/mysql"

MYSQL="$MYSQL_BIN --defaults-extra-file=$MYSQL_ACCESS --skip-column"

QUERY_LIST="/usr/share/zabbix/conf/mysql_query.list"

#
# Error handling:
#  - need to be displayable in Zabbix (avoid NOT_SUPPORTED)
#  - items need to be of type "float" (allow negative + float)
#
ERROR_NO_ACCESS_FILE="-0.9900"
ERROR_NO_ACCESS="-0.9901"
ERROR_WRONG_PARAM="-0.9902"
ERROR_MISSING_QUERY_LIST="-0.9903"
ERROR_QUERY_NOT_EXISTING="-0.9904"

# No mysql access file to read login info from
if [ ! -f "$MYSQL_ACCESS" ]; then
  echo $ERROR_NO_ACCESS_FILE
  exit 1
fi

# Check MySQL access 
echo "" | $MYSQL 2>&1 > /dev/null
if [ $? -ne 0 ]; then
  echo $ERROR_NO_ACCESS
  exit 1
fi

# Check that the configuration file exist and is readable
# and source the file
if [ ! -r "$QUERY_LIST" ]; then
  echo $ERROR_MISSING_QUERY_LIST
  exit 1
else
  source "$QUERY_LIST"
fi

if [ "$ZBX_QUERY" == 'list_query' ]; then
  echo "${QUERY_LIST[@]}"
  exit 0
fi

if [ -z "${!ZBX_QUERY}" ]; then
  echo $ERROR_QUERY_NOT_EXISTING
  exit 1
else
  echo "${!ZBX_QUERY}" | $MYSQL
  exit 0
fi

