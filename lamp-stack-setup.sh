#!/bin/bash

# This script automates installation of the LAMP stack on a RPM machine

# Check if user has sudo privileges
if [[ "${UID}" -ne 0 ]]; then
  echo "Please run script with sudo privileges" >&2
  exit 1
fi

# Default value for exit status
EXIT_STATUS=0

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# Log file
LOG_FILE="/tmp/$SCRIPT_NAME.$(date '+%s')"

# Set timestamp
TIMESTAMP=$(date '+%F_%H:%M:%S')

# Log function
function log {
	local MESSAGE="${@}"

	if [[ "${VERBOSE}" = "true" ]]; then
		# Output message
		echo "${MESSAGE}"
	fi

	# Send message to LOG_FILE
	echo "${TIMESTAMP} || ${MESSAGE}" &>> ${LOG_FILE}

	# And finally send to syslog as well
	logger -t "${SCRIPT_NAME}" "${MESSAGE}"
}

# Log output of command
function logRun {
	# Command to run
	local CMD="${1} | tee -a ${LOG_FILE}"
	
	# Run command
	eval $CMD
}

function myExit {
	# Exit code
	local EXIT_CODE="${1}"
	shift

	# Exit signal ("continue", "exit", "break")
	local EXIT_SIGNAL="${1}"
	shift

	# Message
	local MESSAGE="${@}"

	if [[ "${EXIT_CODE}" -ne 0 ]]; then
		# Output error message
		log "${MESSAGE}"

		# Set EXIT_STATUS to EXIT_CODE
		EXIT_STATUS="${EXIT_CODE}"

		# Check exit signal and use appropriate exit
		case ${EXIT_SIGNAL} in
			"continue") continue ;;
			"break") break ;;
			"exit") exit ${EXIT_CODE} ;;
			*)
				echo "Invalid signal \"${EXIT_SIGNAL}\"" >&2
				echo "Please use 'continue', 'break', or 'exit'" >&2
				exit 1
				;;
		esac
	fi
}

function usage {
	echo >&2
	echo "Usage: ${SCRIPT_NAME} [-vh]"
	echo >&2
	echo "This script is a bash script bootstrap skeleton" >&2
	echo >&2
	echo "	-v	Activate message output (recommended)"
	echo "	-h	Display this message"
	echo >&2
	exit 1
}

# Function to check and install packages
function installPackage {

  local PACKAGES="${@}"

  logRun "yum -y install ${PACKAGES}"

}

# Parse options
while getopts vh OPTION
do
	case ${OPTION} in
		v) VERBOSE="true" ;;
		h) usage ;;
	esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

installPackage "tmux httpd"

# Finish script
exit ${EXIT_STATUS}
