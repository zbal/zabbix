#!/bin/bash
##################################
# Zabbix monitoring script
#
# apache:
#  - anything available via apache stub-status module
#
##################################
# Contact:
#  vincent.viallet@gmail.com
##################################
# ChangeLog:
#  20100922	VV	initial creation
##################################

# Zabbix requested parameter
ZBX_REQ_DATA="$1"
ZBX_REQ_DATA_URL="$2"

# Apache defaults
APACHE_STATS_DEFAULT_URL="http://localhost:80/server-status?auto"
WGET_BIN="/usr/bin/wget"

#
# Error handling:
#  - need to be displayable in Zabbix (avoid NOT_SUPPORTED)
#  - items need to be of type "float" (allow negative + float)
#
ERROR_NO_ACCESS_FILE="-0.9900"
ERROR_NO_ACCESS="-0.9901"
ERROR_WRONG_PARAM="-0.9902"
ERROR_DATA="-0.9903" # either can not connect /	bad host / bad port

# Handle host and port if non-default
if [ ! -z "$ZBX_REQ_DATA_URL" ]; then
  URL="$ZBX_REQ_DATA_URL"
else
  URL="$APACHE_STATS_DEFAULT_URL"
fi

# save the apache stats in a variable for future parsing
APACHE_STATS=$($WGET_BIN -q $URL -O - 2> /dev/null)
TMPSCOREBOARD=$(echo $APACHE_STATS | grep -i scoreboard | sed 's/Scoreboard://')

# error during retrieve
if [ $? -ne 0 -o -z "$APACHE_STATS" ]; then
  echo $ERROR_DATA
  exit 1
fi

# 
# Extract data from apache stats
#
case $ZBX_REQ_DATA in
  version)                  /usr/sbin/httpd -v | awk -F / '{print $2}' | head -1;;
  total_kbytes)             echo "$APACHE_STATS" | grep 'Total kBytes' | awk -F':' '{print $2}';;
  total_accesses)           echo "$APACHE_STATS" | grep 'Total Accesses' | awk -F':' '{print $2}';;
  scoreboard_waiting)       echo "$TMPSCOREBOARD" | grep -o . | grep -c "\_";;
  scoreboard_starting)      echo "$TMPSCOREBOARD" | grep -o . | grep -c "S";;
  scoreboard_sending)       echo "$TMPSCOREBOARD" | grep -o . | grep -c "R";;
  scoreboard_reading)       echo "$TMPSCOREBOARD" | grep -o . | grep -c "W";;
  scoreboard_no-process)    echo "$TMPSCOREBOARD" | grep -o . | grep -c "\.";;
  scoreboard_logging)       echo "$TMPSCOREBOARD" | grep -o . | grep -c "L";;
  scoreboard_keepalive)     echo "$TMPSCOREBOARD" | grep -o . | grep -c "K";;
  scoreboard_idle-cleanup-of-worker)    echo "$TMPSCOREBOARD" | grep -o . | grep -c "I";;
  scoreboard_gracefully-finishing)      echo "$TMPSCOREBOARD" | grep -o . | grep -c "G";;
  scoreboard_dns-lookup)    echo "$TMPSCOREBOARD" | grep -o . | grep -c "D";;
  scoreboard_closing)       echo "$TMPSCOREBOARD" | grep -o . | grep -c "C";;
  scoreboard)               echo "$APACHE_STATS" | grep 'Scoreboard' | awk -F':' '{print $2}';;
  reqpersec)                echo "$APACHE_STATS" | grep 'ReqPerSec' | awk -F':' '{print $2}';;
  idleworkers)              echo "$APACHE_STATS" | grep 'IdleWorkers' | awk -F':' '{print $2}';;
  cpuload)                  echo "$APACHE_STATS" | grep 'CPULoad' | awk -F':' '{print $2}';;
  bytespersec)              echo "$APACHE_STATS" | grep 'BytesPerSec' | awk -F':' '{print $2}';;
  bytesperreq)              echo "$APACHE_STATS" | grep 'BytesPerReq' | awk -F':' '{print $2}';;
  busyworkers)              echo "$APACHE_STATS" | grep 'BusyWorkers' | awk -F':' '{print $2}';;
  *)                        echo $ERROR_WRONG_PARAM; exit 1;;
esac

exit 0
