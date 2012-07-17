#!/bin/bash
##################################
# Zabbix monitoring script
#
# mysql:
#  - MySQL variables
#  - MySQL status
#  - MySQL master / slave status
#
# Info:
#  - mysql data are gathered real-time
#
# Note:
#  
#  - make sure zabbix user has the following sudo config:
#    Cmnd_Alias ZABBIX = ..........., /usr/bin/test, /bin/cat
##################################
# Contact:
#  vincent.viallet@gmail.com
##################################
# ChangeLog:
#  20100922	VV	initial creation
##################################

# Zabbix requested parameter
ZBX_REQ_DATA="$1"
ZBX_REQ_DATA_SOURCE="$2"

# MySQL details
MYSQL_ACCESS="/usr/share/zabbix/conf/my.cnf"
MYSQL_BIN="/usr/bin/mysql"

#MYSQL="$MYSQL_BIN --defaults-extra-file=$MYSQL_ACCESS --skip-column"
MYSQL="$MYSQL_BIN --defaults-extra-file=$MYSQL_ACCESS"

#
# Error handling:
#  - need to be displayable in Zabbix (avoid NOT_SUPPORTED)
#  - numeric items need to be of type "float" (allow negative + float)
#
ERROR_NO_ACCESS_FILE="-0.9900"
ERROR_NO_ACCESS="-0.9901"
ERROR_WRONG_PARAM="-0.9902"

# No mysql access file to read login info from
if [ ! -f "$MYSQL_ACCESS" ]; then
  echo $ERROR_NO_ACCESS_FILE
  exit 1
fi

# Check MySQL access
echo "" | $MYSQL
if [ $? -ne 0 ]; then
  echo $ERROR_NO_ACCESS
  exit 1
fi

# Only ZBX_REQ_DATA is mandatory
# If ZBX_REQ_DATA_SOURCE is not specified, get from mysql global status
if [ -z "$ZBX_REQ_DATA" ]; then
  echo $ERROR_WRONG_PARAM
  exit 1
fi

if [ -z "$ZBX_REQ_DATA_SOURCE" ]; then
  ZBX_REQ_DATA_SOURCE='status'
fi

#############
# Data retrieve methods
#############

get_from_status(){
  param=$1
  value=$(echo "show global status like '$param'" | $MYSQL --skip-column | awk '{print $2}')
  [ -z "$value" ] && echo $ERROR_WRONG_PARAM || echo $value
}

get_from_variables(){
  param=$1
  value=$(echo "show global variables like '$param'" | $MYSQL --skip-column | awk '{print $2}')
  [ -z "$value" ] && echo $ERROR_WRONG_PARAM || echo $value
}

get_from_master(){
  param=$1
  value=$(echo "show master status \G" | $MYSQL | grep -E "^[ ]*$param:" | awk '{print $2}')
  [ -z "$value" ] && echo $ERROR_WRONG_PARAM || echo $value
}

get_from_slave(){
  param=$1
  value=$(echo "show slave status \G" | $MYSQL | grep -E "^[ ]*$param:" | awk '{print $2}')
  [ -z "$value" ] && echo $ERROR_WRONG_PARAM || echo $value
}

get_from_innodb_file(){
  param=$1
  datadir=$($MYSQL --skip-column --silent -e "show global variables like 'datadir';" | awk '{print $2}')
    if [ -z "$datadir" -o ! -e "$datadir" ]; then echo $ERROR_GENERIC; exit 1; fi
  pid_file=$($MYSQL --skip-column --silent -e "show global variables like 'pid_file';" | awk '{print $2}')
    if [ -z "$pid_file" ]; then echo $ERROR_GENERIC; exit 1; fi;
    if sudo /usr/bin/test ! -e "$pid_file" ; then echo $ERROR_GENERIC; exit 1; fi;
  innodb_file=$datadir/innodb_status.$(sudo /bin/cat $pid_file)
    if [ "$innodb_file" == "$datadir/innodb_status." ]; then echo $ERROR_GENERIC; exit 1; fi
  innodb_file_content=$(sudo /bin/cat $innodb_file)
    if [ -z "$innodb_file_content" ]; then echo $ERROR_GENERIC; exit 1; fi

  case $param in
    innodb_row_queries)     echo "$innodb_file_content" | grep 'queries inside InnoDB' | awk '{print $1}';;
    innodb_row_queue)       echo "$innodb_file_content" | grep 'queries inside InnoDB' | awk '{print $5}';;
    history_list_length)    echo "$innodb_file_content" | grep -i 'history list' | awk '{print $4}';;
    *) echo $ERROR_WRONG_PARAM; exit 1;;
  esac
}


# 
# Grab data from mysql for key ZBX_REQ_DATA
#
case $ZBX_REQ_DATA_SOURCE in
  slave)	get_from_slave		"$ZBX_REQ_DATA";;
  master)	get_from_master		"$ZBX_REQ_DATA";;
  status)	get_from_status		"$ZBX_REQ_DATA";;
  variables)	get_from_variables	"$ZBX_REQ_DATA";;
  innodb_file) 	get_from_innodb_file "$ZBX_REQ_DATA";;
  *) echo $ERROR_WRONG_PARAM; exit 1;;
esac

exit 0


