#!/bin/bash

# This script is a tool to perform backups and restorations of mysql databases

# Assign default variable to destination directory of backups
DESTINATION_DIR="/mysql_backups"

# Set default exit status
EXIT_STATUS=0

# Set timestamp for current time (%N is nanoseconds, so it will still sort on ls)
TIMESTAMP=$(date '+%F.%N')

# Log function
function log {
  local MESSAGE="${@}"

  echo "${MESSAGE}"

  if [[ "${VERBOSE}" = "true" ]]; then
    echo "${MESSAGE}"
  fi

  # send to syslog
  logger -t "${0}" "${MESSAGE}"
}

# Error checking function
function exit_script {

  # Get exit code
  local EXIT_CODE="${1}"
  shift

  # Exit signal ("continue", "exit", "break")
  local EXIT_SIGNAL="${1}"
  shift

  # Message to output
  local MESSAGE="${@}"

  # Check for error signal, bit of WET here (Write Everything Twice), but at least it's in a function
  if [[ "${EXIT_CODE}" -ne 0 ]]; then
    case ${EXIT_SIGNAL} in
      "continue") log "${MESSAGE}" ; continue ;;
      "break") log "${MESSAGE}" ; break ;;
      "exit") log "${MESSAGE}" ; exit "${EXIT_CODE}" ;;
    esac
  else
    case ${EXIT_SIGNAL} in
      "continue") log "${MESSAGE}" ; continue ;;
      "break") log "${MESSAGE}" ; break ;;
      "exit") log "${MESSAGE}" ; exit "${EXIT_CODE}" ;;
    esac
  fi
}

# Usage statement
function usage {
  echo >&2
  echo "Usage: ${0} [-v] [-b DB1,DB2]... [-r DB1,DB2]... [-n NODE1,NODE2]... [-f DIR] [-p PASSWORD]" >&2
  echo >&2
  echo "This script is a tool to perform mysql database backups and restores." >&2
  echo >&2
  echo "  -v            Activate output of messages" >&2
  echo "  -b DATABASES  Backup DATABASES to ${DESTINATION_DIR}" >&2
  echo "  -r DATABASES  Restore DATABASES to the server" >&2
  echo "  -n NODES      List of hostnames or IPs to copy the backup to" >&2
  echo "  -f FOLDER     Override default destination directory ${DESTINATION_DIR}" >&2
  echo "  -p PASSWORD   Only use it if running automated backups" >&2
  echo >&2
  exit 1
}






usage



















