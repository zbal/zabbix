#!/bin/bash
##################################
# Zabbix monitoring script
#
# ss:
#  - gives stats about network/unix connection states
# example:
#  - can count amount of established connections to mysql
#
# zabbix item format:
#  ss[proto,connection_state,dest,dest_port]
#    - proto: all, tcp, udp, unix
#    - connection_state: established, syn-sent, syn-recv, fin-wait-1, fin-wait-2, 
#                    time-wait, closed, close-wait, last-ack, listen and closing. 
#    - dest: either hostname / IP or 
##################################
# Contact:
#  vincent.viallet@gmail.com
##################################
# ChangeLog:
#  20100922	VV	initial creation
##################################

# Zabbix requested parameter
ZBX_REQ_DATA_PROTO="$1"
ZBX_REQ_DATA_STATE="$2"
ZBX_REQ_DATA_DEST="$3"
ZBX_REQ_DATA_PORT="$4"

# ss defaults
SS_BIN="/usr/sbin/ss"

#
# Error handling:
#  - need to be displayable in Zabbix (avoid NOT_SUPPORTED)
#  - items need to be of type "float" (allow negative + float)
#
ERROR_NO_ACCESS_FILE="-0.9900"
ERROR_NO_ACCESS="-0.9901"
ERROR_WRONG_PARAM="-0.9902"
ERROR_DATA="-0.9903" # either can not connect /	bad host / bad port

#
# Check parameters validity
#
# Check protocol
if [ -z "$(echo $ZBX_REQ_DATA_PROTO | grep -E 'all|tcp|udp|unix')" ]; then
  echo $ERROR_WRONG_PARAM
  exit 1
fi
# Check connection status
if [ -z "$(echo $ZBX_REQ_DATA_STATE | grep -E 'established|syn-sent|syn-recv|fin-wait-1|fin-wait-2|time-wait|closed|close-wait|last-ack|listen|closing')" ]; then
  echo $ERROR_WRONG_PARAM
  exit 1
fi

# Prepare SS command based on the arguments provided in the command-line
CUSTOM_CMD="$SS_BIN -n -A $ZBX_REQ_DATA_PROTO state $ZBX_REQ_DATA_STATE"
EXTRA_LINES=0

if [ "$ZBX_REQ_DATA_PROTO" == "unix" ]; then
  if [ ! -z "$ZBX_REQ_DATA_DEST" ]; then
    CUSTOM_CMD="$CUSTOM_CMD -p | grep $ZBX_REQ_DATA_DEST"
    EXTRA_LINES=0
  else
    EXTRA_LINES=1
  fi
else
  if [ ! -z "$ZBX_REQ_DATA_DEST" ]; then
    CUSTOM_CMD="$CUSTOM_CMD dst $ZBX_REQ_DATA_DEST"
  fi
  if [ ! -z "$ZBX_REQ_DATA_PORT" ]; then
    CUSTOM_CMD="$CUSTOM_CMD dport eq :$ZBX_REQ_DATA_PORT"
  fi
  EXTRA_LINES=1
fi

# Count number of lines in the output of ss
VALUE=$($CUSTOM_CMD | wc -l)
if [ $? -ne 0 ]; then
  echo $ERROR_WRONG_PARAM
  exit 1
fi

# Remove extra line if needed (title line)
VALUE_RETURN=$(($VALUE-$EXTRA_LINES))
echo $VALUE_RETURN

exit 0
