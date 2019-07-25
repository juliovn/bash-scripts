#!/bin/bash

# This script simulates the common "trash can/bin" behaviour of systems like
# windows or macos, wherein a user deletes a file it goes to a
# trash directory where it can be retrieved, script also provides an option to
# perform a cleanup of this directory

# Assign trash directory to variable
TRASH_DIR="${HOME}/.trash"

# Set default exit status
EXIT_STATUS=0

# Function that logs messages to standard output and to syslog
function log {
    local MESSAGE="${@}"
    if [[ "${VERBOSE}" = "true" ]]; then
        echo "${MESSAGE}"
    fi
    logger -t "${0}" "${MESSAGE}"
}

# Error checking function - will take exit code as first parameter and the rest a message to output
function fail_quit {
    CODE="${1}"
    shift
    MESSAGE="${@}"
    
    if [[ "${CODE}" -ne 0 ]]; then
        echo "${MESSAGE}" >&2
        exit 1
    fi
}

# Function that will output script usage
function usage {
  echo "Usage: ${0} [-vc] FILES" >&2
  echo "This script will take FILES and move it to ${TRASH_DIR}" >&2
  echo "  -v  See the output and messages" >&2
  echo "  -c  Perform cleanup of ${TRASH_DIR} - this will delete all files inside" >&2
  exit 1
}

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Parse options
while getopts vc OPTION
do
  case ${OPTION} in
    v)
      VERBOSE="true"
      ;;
    c)
      CLEANUP="true"
      ;;
    ?)
      usage
      ;;
  esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

# Make sure that the $HOME/.trash directory exists, otherwise create it
if [[ ! -d "${TRASH_DIR}" ]]; then
  mkdir -p ${TRASH_DIR}
fi

# Check if cleanup option has been passed
if [[ "${CLEANUP}" = "true" ]]; then

  # Get confirmation from user
  read -p "WARNING: This will delete all files inside ${TRASH_DIR}, are you sure you want to continue? [y/n] " CONFIRMATION

  if [[ "${CONFIRMATION}" != "y" ]]; then
    fail_quit 1 "Confirmation not given for cleanup, exiting..."
  fi

  log "Performing cleanup..."

  # Remove trah directory
  rm -rf ${TRASH_DIR}

  fail_quit "${?}" "Failed to cleanup ${TRASH_DIR}"

  log "Cleanup finished successfully"

  # Exit script successfully
  exit 0
fi

# Loop through file list
for FILE in "${@}"; do

  # Check if file exist
  if [[ ! -a "${FILE}" ]]; then
    echo "${FILE} does not exist" >&2
    EXIT_STATUS=1
    continue
  fi

  # Check if file is a directory
  if [[ -d "${FILE}" ]]; then
    CP_OPTIONS="-pr"
  fi

  # Check if user has ownership of file (second check added to make sure root can bypass this)
  if [[ ! -O "${FILE}" && "${UID}" -ne 0 ]]; then
    echo "You do not own ${FILE}" >&2
    EXIT_STATUS=1
    continue
  fi

  # Copy directory to trash directory
  cp ${CP_OPTIONS} ${FILE} ${TRASH_DIR} &> /dev/null

  if [[ "${?}" -ne 0 ]]; then
    echo "Could not copy ${FILE} to ${TRASH_DIR}" >&2
    EXIT_STATUS=1
    continue
  fi

  # Remove directory
  rm -rf ${FILE} &> /dev/null

  if [[ "${?}" -ne 0 ]]; then
    echo "Could not remove ${FILE}"
    EXIT_STATUS=1
    continue
  fi

  # Output success message
  log "${FILE} successfully sent to ${TRASH_DIR}"
done

# Finish script
exit ${EXIT_STATUS}

