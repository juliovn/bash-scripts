#!/bin/bash

#%
#% ${SCRIPT_NAME} - find IPs from apache log with a lot of hits
#%
#% usage: ${SCRIPT_NAME} log_file
#%

# Set the default exit status
EXIT_STATUS=0

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# Limit of access
LIMIT='10'

# Log file
LOG_FILE="${1}"

# If no params are passed output usage
if [ $# -lt 1 ]; then
	awk -v SCRIPT_NAME="${SCRIPT_NAME}" '/^#%/ {gsub("[$]{SCRIPT_NAME}", SCRIPT_NAME, $0); print substr($0,3)}' $0
	exit 1
fi

# Make sure a file was supplied as an argument.
if [[ ! -e "${LOG_FILE}" ]]
then 
  echo "Cannot open log file: ${LOG_FILE}" >&2
  exit 1
fi

# Display the CSV header.
echo 'Count,IP,Location'

cat ${LOG_FILE} | awk '{print $1}' | sort | uniq -c | sort -nr | while read COUNT IP
do

	# If count goes over LIMIT display data
	if [[ "${COUNT}" -gt "${LIMIT}" ]]; then
    	LOCATION=$(geoiplookup ${IP} | awk -F ', ' '{print $2}')
    	echo "${COUNT},${IP},${LOCATION}"
	fi

done

exit 0
