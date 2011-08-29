#!/bin/bash
##################################
# Zabbix monitoring script
#
# varnish:
#  - anything available via varnishstat
##################################
# Contact:
#  vincent.viallet@gmail.com
##################################
# ChangeLog:
#  20110829	VV	initial creation
##################################

# Zabbix requested parameter
ZBX_REQ_DATA="$1"

#
# Error handling:
#  - need to be displayable in Zabbix (avoid NOT_SUPPORTED)
#  - items need to be of type "float" (allow negative + float)
#
ERROR_WRONG_PARAM="-0.9900"
ERROR_DATA="-0.9901"

# save the varnish stats in a variable for future parsing
VARNISH_VALUE=$(varnishstat -1 -f $ZBX_REQ_DATA | awk '{print $2}')

# error during retrieve
if [ $? -ne 0 -o -z "$VARNISH_VALUE" ]; then
  echo $ERROR_DATA
  exit 1
fi

echo $VARNISH_VALUE
exit 0
