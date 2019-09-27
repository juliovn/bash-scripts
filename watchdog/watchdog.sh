#!/bin/bash

# This script will check if a specific service is running on host and
# if necessary restart it and send an email alert

# Path to config files
CONFIG_DIR="$(pwd)/service_check"

# Set the default exit status
EXIT_STATUS=0

# Log file
LOG_FILE="/tmp/$SCRIPT_NAME.$$"

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# Set timestamp
TIMESTAMP=$(date '+%F_%H:%M:%S')

# Check if user has sudo privileges
if [[ "${UID}" -ne 0 ]]; then
  echo "Please run script with sudo privileges" >&2
  exit 1
fi

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
    log "${MESSAGE}"

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

# Send email reports
function send_reports {
  log "Sending reports..."

  # Loop through email list
  for EMAIL in $(echo "${EMAILS}" | tr "," "\n"); do

    # Email variables
    local SUBJECT="[${SCRIPT_NAME}] | some resources are DOWN on ${HOSTNAME}!"
    local SENDER="${HOSTNAME}"

    mail -s "${SUBJECT}" -S from=${SENDER} "${EMAIL}" <<<EOF
${SCRIPT_NAME} deteceted some resources are down on ${HOSTNAME}, here are the contents of the log file:

$(cat ${LOG_FILE})
EOF

  fail_quit "${?}" "continue" "Could not send email to ${EMAIL}"

  done
}

# Check for services
function check_if_running {

  local SERVICE_NAME="${1}"
  local SERV_CHECK_FILE="${CONFIG_DIR}/${SERVICE_NAME}.check"
  local SERV_CMD_FILE="${CONFIG_DIR}/${SERVICE_NAME}.serv"

  if [[ ! -s "${SERV_CHECK_FILE}" || ! -s "${SERV_CMD_FILE}" ]]; then
    fail_quit 1 "continue" "Please make sure to configure ${SERV_CHECK_FILE} and ${SERV_CMD_FILE} before proceeding..."
  fi

  log "Checking status for ${SERVICE_NAME} by running ${SERV_CHECK_FILE}..."

  # Run .check file
  ${SERV_CHECK_FILE}

  echo ${?}

}

# Usage statement
function usage {
	echo >&2
	echo "Usage: ${SCRIPT_NAME} [options] [-s SERVICE1,SERVICE2] [-e EMAIL1,EMAIL2]..." >&2
	echo >&2
	echo "This is a service monitoring script" >&2
	echo "To work you will need to create .check and .serv files on ${CONFIG_DIR} directory" >&2
	echo >&2
  echo " -s  SERVICES Services to check and restart" >&2
	echo " -e  EMAILS   List of emails that will receive alert in case service is restarted" >&2
	echo " -v           Activate message output" >&2
	echo " -h           See this usage statement" >&2
	echo >&2
	exit 1
}

# Parse options
while getopts vhs:e: OPTION
do
  case ${OPTION} in
    v) VERBOSE="true" ;;
    h) usage ;;
    s) SERVICES="${OPTARG}" ;;
    e) EMAILS="${OPTARG}" ;;
    ?) usage ;;
  esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

# Check if CONFIG_DIR exists
if [[ ! -s "${CONFIG_DIR}" ]]; then
  fail_quit 1 "exit" "Please make sure ${CONFIG_DIR} exists before running"
fi

# Check services
if [[ -n "${SERVICES}" ]]; then

  # Loop through services list
  for SERVICE in $(echo "${SERVICES}" | tr "," "\n"); do

    # Check for service
    check_if_running "${SERVICE}"

  done

fi

# Remove log file
rm -f ${LOG_FILE}

# Finish script
exit ${EXIT_STATUS}
