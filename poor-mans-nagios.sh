#!/bin/bash

# This script will perform monitoring of host and web domains and will
# send alerts in case those resources are down

# "Down" as far as this script is concerned is non-200 html return code
# or host not responding to ping

# Set the default exit status
EXIT_STATUS=0

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# Log file
LOG_FILE="/tmp/$SCRIPT_NAME.$$"

# Set timestamp
TIMESTAMP=$(date '+%F_%H:%M:%S')

# Logging function
function log {
	local MESSAGE="${@}"

	if [[ "${VERBOSE}" = "true" ]]; then
		# Output to screen
		echo "${MESSAGE}"
	fi

	# Send to LOG_FILE
	echo "${TIMESTAMP} || ${MESSAGE}" &>> ${LOG_FILE}

	# And send to syslog as well
	logger -t "${SCRIPT_NAME}" "${MESSAGE}"
}

# Error checking function
function fail_quit {
  # Exit code
  local EXIT_CODE="${1}"
  shift

  # Exit signal ("continue", "exit", "break")
  local EXIT_SIGNAL="${1}"
  shift

  # Message to output
  local MESSAGE="${@}"

  if [[ "${EXIT_CODE}" -ne 0 ]]; then
    # Output error message
    log "${TIMESTAMP} | ${MESSAGE}"

    # Set EXIT_STATUS to EXIT_CODE
    EXIT_STATUS="${EXIT_CODE}"

    # Check for exit signal and use the appropriate exit
    case ${EXIT_SIGNAL} in
      "continue") continue ;;
      "break") break ;;
      "exit") exit ${EXIT_CODE} ;;
      *)
        echo "Invalid signal ${EXIT_SIGNAL} passed" >&2
        echo "Please use 'continue', 'break', or 'exit'" >&2
        exit 1
        ;;
    esac
  fi
}

# Usage statement
function usage {
  echo >&2
  echo "Usage: ${SCRIPT_NAME} [-d DOMAIN1,DOMAIN2]... [-h HOST1,HOST2]... [-e EMAIL1,EMAIL2]" >&2
  echo >&2
  echo "This script monitors hosts and website addresses and shoots emails in case of any resources down" >&2
  echo >&2
  echo "  -v           Activate message output" >&2
  echo "  -c  DOMAINS  Will check DOMAINS for non-200 html return code" >&2
  echo "  -h  HOSTS    Will check HOSTS and try a ping" >&2
  echo "  -e  EMAILS   Send report to EMAILS in case any resource is down" >&2
  echo >&2
  exit 1
}

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Parse options
while getopts vc:h:e: OPTION
do
	case ${OPTION} in
		v) VERBOSE="true" ;;
		c) DOMAINS="${OPTARG}" ;;
		h) HOSTS="${OPTARG}" ;;
		e) EMAILS="${OPTARG}" ;;
		?) usage ;;
	esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"
