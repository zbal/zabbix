#!/bin/bash
###############################
# Zabbix column reader monitoring
###############################
# Contact :
#  vincent.viallet@gmail.com
###############################
# Usage :
#	arg1 : file name
#	arg2 : column # to extract (integer)
#   arg3 : matching regex (optional)
#   arg4 : specific line (optional)
#   arg5 : delimiter (optional - default space / tabs)
#
# Either regex or specific line NEED to be specified.
# If both are specified, specific line will apply to the matched lines by regex
#
###############################
# Security :
#   Due to some limitation in the ownership of some log files
#   it is necessary to provide zabbix user with some extra privileges
#
#   To sudo configuration add the following binaries to the list of allowed
#   binary to be run as admin by zabbix user :
#
# Cmnd_Alias ZABBIX = ..........., /usr/bin/test, /usr/bin/cat
###############################

# Arguments
#  Log_file_name -- full path 
#  log match -- the matching pattern we want to retrieve a count for
EXTRACT_FILE_NAME="$1"
EXTRACT_COLUMN="$2"
EXTRACT_REGEX="$3"
EXTRACT_LINE="$4"
EXTRACT_DELIMITER="$5"

# Error codes
ERROR_BAD_OUTPUT="-0.9902"
ERROR_BAD_ARGUMENT="-0.9903"
ERROR_NOT_READABLE="-0.9904"
ERROR_BAD_PERMISSIONS="-0.9905"

# Binary definition
CAT=cat

# Validate arguments
# Ensure file name is specified
if [ -z "$EXTRACT_FILE_NAME" ]; then
	echo "$ERROR_BAD_ARGUMENT"
	exit 1
fi
# Ensure column is specified -- TODO, if not specified return entire line instead
# Ensure column is integer
if [ -z "$EXTRACT_COLUMN" ]; then
	echo "$ERROR_BAD_ARGUMENT"
	exit 1
else
  if [ $(echo "$EXTRACT_COLUMN" | grep -cE '^[0-9]+$') -ne 1 ]; then
	  echo "$ERROR_BAD_ARGUMENT"
		exit 1
	fi
fi
# Ensure either Regex or Line is specified
if [ -z "$EXTRACT_REGEX" -a -z "$EXTRACT_LINE" ]; then
	echo "$ERROR_BAD_ARGUMENT"
	exit 1
fi
# Ensure integer only
if [ ! -z "$EXTRACT_LINE" ]; then
  if [ $(echo "$EXTRACT_LINE" | grep -cE '^[0-9]+$') -ne 1 ]; then
	  echo "$ERROR_BAD_ARGUMENT"
		exit 1
	fi
fi


# Test if log is readable by normal user - if not try with sudo
# exit if log file is not readable
if [ ! -r "$EXTRACT_FILE_NAME" ]; then
	CAT='sudo /bin/cat'
  # test if even with sudo we can not read
	if [ $(sudo /usr/bin/test -r "$EXTRACT_FILE_NAME") ]; then
  	echo "$ERROR_NOT_READABLE"
  	exit 1
  fi
fi


# Save file content to variable
FILE_CONTENT=$($CAT "$EXTRACT_FILE_NAME")
# Default sub_content is the entire file - can be reduced after
FILE_SUB_CONTENT="$FILE_CONTENT"

# Refine sub-content through regex if defined
if [ ! -z "$EXTRACT_REGEX" ]; then
	FILE_SUB_CONTENT=$(echo "$FILE_SUB_CONTENT" | grep -E "$EXTRACT_REGEX")
fi

# Refine sub-content through line number if defined
if [ ! -z "$EXTRACT_LINE" ]; then
	FILE_SUB_CONTENT=$(echo "$FILE_SUB_CONTENT" | sed -n "$EXTRACT_LINE p")
fi

# Extract column with custom delimiter if specified
AWK_DELIMITER=''
if [ ! -z "$EXTRACT_DELIMITER" ]; then
	AWK_DELIMITER="-F$EXTRACT_DELIMITER"
fi
OUTPUT=$(echo "$FILE_SUB_CONTENT" | awk $AWK_DELIMITER "{ print \$$EXTRACT_COLUMN }")


# We only want single line answer - report error if no result or more than 1 line in OUTPUT
if [ -z "$OUTPUT" ]; then
	echo "$ERROR_BAD_OUTPUT"
	exit 1
elif [ $(echo "$OUTPUT" | wc -l) -gt 1 ]; then
	echo "$ERROR_BAD_OUTPUT"
	exit 1
else
    echo "$OUTPUT"
fi
