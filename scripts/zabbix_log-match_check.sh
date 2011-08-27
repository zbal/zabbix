#!/bin/bash
###############################
# Zabbix log monitoring
###############################
# Contact :
#  vincent.viallet@gmail.com
###############################
# Limitations :
#	  Currently resume reading from previously read offset
#	  If inode is different -> new file, re-read from 0
#	  Do not handle rotated logs (yet)
###############################
# Usage :
#	  arg1 : log file name
#	  arg2 : matching pattern
#   arg3 : matching type (raw / web / more in the future)
#   arg4 : data type (count / sum) - count is easier for trigger
#             sum is better for delta in Zabbix
#
# Special matching type :
#	  web : matching arg can be set to  2xx 3xx 4xx 5xx
#		      this pattern will then be changed to be 2[0-9]{2} / etc.
#   raw : base regexp match on the log file
###############################
# Security :
#   Due to some limitation in the ownership of some log files
#   it is necessary to provide zabbix user with some extra privileges
#
#   To sudo configuration add the following binaries to the list of allowed
#   binary to be run as admin by zabbix user :
#
# Cmnd_Alias ZABBIX = ..........., /usr/bin/stat, /usr/bin/tail, /usr/bin/test
###############################

# Define configuration / stat file
# Format :
#     file_name:return_code:inode:offset:count
STAT_FILE=/home/zabbix/data/log.stat

# Arguments
#  Log_file_name -- full path 
#  log match -- the matching pattern we want to retrieve a count for
LOG_FILE_NAME="$1"
LOG_MATCH="$2"
LOG_MATCH_TYPE="$3"
LOG_RESULT_TYPE="$4"

# Error codes
ERROR_NOT_READABLE="-0.9904"
ERROR_BAD_PERMISSIONS="-0.9905"

# Binary definition
STAT=stat
TAIL=tail

# Test if log is readable by normal user - if not try with sudo
# exit if log file is not readable
if [ ! -r "$LOG_FILE_NAME" ]; then
	STAT='sudo /usr/bin/stat'
	TAIL='sudo /usr/bin/tail'
  # test if even with sudo we can not read
	if [ $(sudo /usr/bin/test -r "$LOG_FILE_NAME") ]; then
  	echo "$ERROR_NOT_READABLE"
  	exit 1
  fi
fi

# Create stat if not existing
if [ ! -e "$STAT_FILE" ]; then
	cat > "$STAT_FILE" << EOF
#############################################################
# Log file : match pattern : log inode : log offset : count #
#############################################################
EOF
	if [ $? -ne 0 ]; then
		echo "$ERROR_BAD_PERMISSIONS"
		exit 1
	fi
fi

get_current_stat() {
	LOG_INODE=$($STAT -c "%i" $LOG_FILE_NAME)
	LOG_SIZE=$($STAT -c "%s" $LOG_FILE_NAME)
	LOG_OFFSET=$LOG_SIZE
}

# Retrieve offset from stat file
# If absent - OFFSET=0 - will then be added in the stat for next check
get_offset() {
	INODE=$(grep -E "^$LOG_FILE_NAME:$LOG_MATCH:" $STAT_FILE | cut -f 3 -d':' )
	
	# file not defined in stat file
	#	OFFSET set to 0
	#	COUNT set to 0 (first check)
	if [ -z "$INODE" ]; then
		OFFSET=0
		COUNT=0
		return
	fi

	OFFSET=$(grep -E "^$LOG_FILE_NAME:$LOG_MATCH:" $STAT_FILE | cut -f 4 -d':' )
	COUNT=$(grep -E "^$LOG_FILE_NAME:$LOG_MATCH:" $STAT_FILE | cut -f 5 -d':' )
	
	# Saved inode is different from current file
	#	OFFSET back to 0
	if [ $((INODE)) -ne $((LOG_INODE)) ]; then
		OFFSET=0
	fi
	
	# Saved file size (offset) is larger than actual size
	# suggests erase of file content (ie. echo > LOG_FILE)
	#	OFFSET back to 0
	if [ $((OFFSET)) -gt $((LOG_SIZE)) ]; then
		OFFSET=0
	fi

	return
}

# Update statistic file (either update or create)
update_stat() {
	if [ $(grep -cE "^$LOG_FILE_NAME:$LOG_MATCH:" $STAT_FILE) -ne 0 ]; then
		# Protect slash for sed
		STAT_FILE_MATCH=$(echo "$LOG_FILE_NAME:$LOG_MATCH" | sed -e 's/\//\\\//g')
		# Update INODE
		sed -i "/^$STAT_FILE_MATCH:/ s/:[^:]*/:$LOG_INODE/2" $STAT_FILE 
		# Update OFFSET
		sed -i "/^$STAT_FILE_MATCH:/ s/:[^:]*/:$LOG_OFFSET/3" $STAT_FILE
		# Update COUNT
		sed -i "/^$STAT_FILE_MATCH:/ s/:[^:]*/:$COUNT/4" $STAT_FILE
	else
		echo "$LOG_FILE_NAME:$LOG_MATCH:$LOG_INODE:$LOG_OFFSET:$COUNT" >> $STAT_FILE
	fi
}

# Count web return code
# Rely on the base log format :
#	xxxxxxxxxx RETURN_CODE RESPONSE_SIZE xxxxxxxxxxx
match_web_return_code() {
	# Handle 2xx / 3xx / 4xx / 5xx -- other remain unchanged
	case $LOG_MATCH in
		2xx) PATTERN='2[0-9]{2}';;
		3xx) PATTERN='3[0-9]{2}';;
		4xx) PATTERN='4[0-9]{2}';;
		5xx) PATTERN='5[0-9]{2}';;
		*) PATTERN="$LOG_MATCH"
	esac
	NEW_COUNT=$($TAIL -c +$OFFSET $LOG_FILE_NAME | grep -cE " $PATTERN [0-9]")
	COUNT=$((COUNT+NEW_COUNT))
	echo $COUNT
}

# Match raw patterns
match_raw() {
  PATTERN="$LOG_MATCH"
  NEW_COUNT=$($TAIL -c +$OFFSET $LOG_FILE_NAME | grep -cE "$PATTERN")
  COUNT=$((COUNT+NEW_COUNT))
  echo $COUNT
}

main() {
	get_current_stat
	get_offset
	case $LOG_MATCH_TYPE in
	  web) match_web_return_code;;
	  raw) match_raw;;
	  *) match_web_return_code;;
  esac
	update_stat
}

main

