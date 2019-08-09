#!/bin/bash

# This script is a monitoring tool that will check for services that are down
# and perform a number of actions to restart the service

# Set the default exit status
EXIT_STATUS=0

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# Default configuration file
CONF_FILE="$HOME/watchdog.conf.${HOSTNAME}"

# Log file
LOG_FILE="/tmp/${SCRIPT_NAME}.log.${HOSTNAME}.$$"

# Include the path to the pidof command
PATH="${PATH}:/usr/sbin"

# Set timestamp
TIMESTAMP=$(date '+%F_%H:%M:%S')

# Log function
function log {
  local MESSAGE="${@}"

  if [[ "${VERBOSE}" = "true" ]]; then
    # Output to screen if verbose is true
    echo "${MESSAGE}"
  fi

  # Send to LOG_FILE
  echo "${MESSAGE}" &>> ${LOG_FILE}

  # Send to syslog
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
  echo "Usage: ${SCRIPT_NAME}" >&2
  echo >&2
  echo "This script monitors services for their status and restarts in case a service is down" >&2
  echo >&2
  echo "  -v              Activate message output" >&2
  echo "  -c  CONF_FILE   Override default configuration file ${CONF_FILE}" >&2
  echo "  -e  EMAILS      List of emails to send the log file report" >&2
  echo >&2
  exit 1
}

# Make sure user is root
if [[ "${UID}" -ne 0 ]]; then
  fail_quit 1 "exit" "Please run with superuser privileges."
fi

# Main function that will restart services
# This will take two args:
# 1 - name of the service/process
# @ - command to restart
function restart_service {

  # Get service name
  local SERVICE_NAME="${1}"
  shift

  # Get command to restart
  local SERVICE_CMD="${@}"

  log "${TIMESTAMP} | Checking if ${SERVICE_NAME} is running..."

  local SERVICE_PID=$(pidof ${SERVICE_NAME})

  if [[ -n "${SERVICE_PID}" ]]; then
    # Service is running
    log "${TIMESTAMP} | ${SERVICE_NAME} is running with PID(s): ${SERVICE_PID}"
  else
    log "${TIMESTAMP} | ${SERVICE_NAME} is not running, restarting..."
    
    ${SERVICE_CMD} &>> ${LOG_FILE}
    
    fail_quit "${?}" "continue" "Could not start ${SERVICE_NAME} with ${SERVICE_CMD}"

    log "${TIMESTAMP} | ${SERVICE_NAME} restarted successfully"
  fi

}

# Send report function
function send_report {

  # Loop through list of emails
  for EMAIL in $(echo "${1}" | tr "," "\n"); do

    local SUBJECT="${SCRIPT_NAME} report from ${HOSTNAME} [${LOG_FILE}]"
    local SENDER="${HOSTNAME}"
    local RECEIVER="${EMAIL}"

    mail -s "${SUBJECT}" -S from=${SENDER} "${RECEIVER}" < ${LOG_FILE}

  done

}

# Parse options
while getopts hvc:e: OPTION
do
  case ${OPTION} in
    h) usage ;;
    v) VERBOSE="true" ;;
    c) CONF_FILE="${OPTARG}" ;;
    e) EMAILS="${OPTARG}" ;;
    ?) usage ;;
  esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

# Make sure configuration file exists
if [[ ! -e "${CONF_FILE}" ]]; then
  fail_quit 1 "exit" "Could not read configuration file."
fi

while read LINE
do
  # Check if line is empty
  if [[ -z "${LINE}" ]]; then
    continue
  fi

  restart_service ${LINE}
done < ${CONF_FILE}

# Send report
if [[ -n "${EMAILS}" ]]; then

  # Check if there has been any services restarted, otherwise dont send mail
  if ! grep -q "not running" ${LOG_FILE} ; then
    fail_quit 1 "exit" "No services restarted, report was not sent."
  fi

  send_report "${EMAILS}"
fi

# Finish script
exit ${EXIT_STATUS}



