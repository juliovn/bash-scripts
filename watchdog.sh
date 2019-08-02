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
LOG_FILE="$HOME/watchdog.log.${HOSTNAME}"

# Log function
function log {
  local MESSAGE="${0}"

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
    echo "${MESSAGE}" >&2

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
  echo "  -v          Activate message output" >&2
  echo "  -c  FILE    Override default configuration file ${CONF_FILE}" >&2
  echo "  -e  EMAILS  List of emails to send ${LOG_FILE} report" >&2
  echo >&2
  exit 1
}





