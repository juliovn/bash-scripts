#!/bin/bash

# This script is a tool to perform backups and restorations of mysql databases

# Assign default variable to destination directory of backups
DESTINATION_DIR="$HOME/mysql_backups"

# Set default exit status
EXIT_STATUS=0

# Set timestamp for current time (%N is nanoseconds, so it will still sort on ls)
TIMESTAMP=$(date '+%F-%N')

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# Log function
function log {
  local MESSAGE="${@}"

  if [[ "${VERBOSE}" = "true" ]]; then
    echo "${MESSAGE}"
  fi
}

# Error checking function
function fail_quit {
  # exit code
    CODE="${1}"
    shift

    # Exit signal ("continue", "exit", "break")
    EXIT_SIGNAL="${1}"
    shift

    # Message to output
    MESSAGE="${@}"
    
    if [[ "${CODE}" -ne 0 ]]; then
        echo "${MESSAGE}" >&2
        
        case ${EXIT_SIGNAL} in
          "continue")
                EXIT_STATUS="${CODE}"
                continue
        ;;
      "break")
        break
        ;;
      "exit")
        exit ${CODE}
        ;;
      *)
        echo "Invalid signal ${EXIT_SIGNAL} passed" >&2
        echo "Please use 'continue', 'break' or 'exit'" >&2
                ;;
        esac
    fi
}

# Usage statement
function usage {
  echo >&2
  echo "Usage: ${SCRIPT_NAME} -d DATABASE [-vb] [-r FILE ]... [-n NODE1,NODE2]... [-f DIR] [-p PASSWORD]" >&2
  echo >&2
  echo "This script is a tool to perform mysql database backups and restores." >&2
  echo >&2
  echo "  -d DATABASE  ::  Define which DATABASE will be operated upon" >&2
  echo "  -v           ::  Activate output of messages" >&2
  echo "  -b           ::  Backup DATABASE to ${DESTINATION_DIR}" >&2
  echo "  -r FILE.sql  ::  Restore FILE.sql to DATABASE" >&2
  echo "  -n NODES     ::  List of hostnames or IPs to copy the backup to" >&2
  echo "  -f DIR       ::  Override default destination directory ${DESTINATION_DIR}" >&2
  echo "  -p PASSWORD  ::  Only use it if running automated backups" >&2
  echo "  -h           ::  Displays this usage statement" >&2
  echo >&2
  exit 1
}

# Backup database function
function backup_database {

  # Generate name for backup file
  local BACKUP_FILE="${DESTINATION_DIR}/${DATABASE}-${TIMESTAMP}.sql"

  log "Creating backup for ${DATABASE}..."

  # Dump database to file
  mysqldump -u root -p${PASSWORD} ${DATABASE} &> /dev/null > ${BACKUP_FILE}

  if [[ "${?}" -ne 0 ]]; then
    echo "Could not dump ${DATABASE} into ${BACKUP_FILE}" >&2
    # clean up backup file
    rm -f ${BACKUP_FILE}
    exit 1
  fi

  # Check if NODES is defined and call function to ship backups to remote
  if [[ -n "${NODES}" ]]; then
    log "Shipping backup to remote nodes..."
    send_to_remotes "${BACKUP_FILE}"
  fi

  # exit successfully
  log "Backup saved to ${BACKUP_FILE}"
  exit 0
}

# Restore database function
function restore_database {

  # Try to create database in case it does not exist
  log "Creating database..."
  mysqladmin -u root -p${PASSWORD} create ${DATABASE} &> /dev/null

  # Restore database with sql file
  log "Restoring database..."
  mysql -u root -p${PASSWORD} ${DATABASE} &> /dev/null < ${RESTORE}

  fail_quit "${?}" "exit" "Could not restore ${DATABASE} with file ${RESTORE}"

  # exit successfully
  log "Restore of ${DATABASE} with file ${RESTORE} completed."
  exit 0
}

# Function that will ship backups to remote hosts
function send_to_remotes {

  # Define file to send
  local FILE="${1}"

  # Define timeout of 2 so doesn't hang for too long if host is down
  local SSH_OPTIONS="-o ConnectTimeout=4"

  # loop through NODES list
  for NODE in $(echo "${NODES}" | tr "," "\n"); do
    # Assign command to variable
    SSH_CMD="ssh ${SSH_OPTIONS} ${NODE}"

    # Create directory to hold backups on remote host
    ${SSH_CMD} "mkdir -p ${DESTINATION_DIR}" &> /dev/null

    # Copy FILE into the directory
    scp ${FILE} ${NODE}:${DESTINATION_DIR} &> /dev/null

    # Check for errors
    fail_quit "${?}" "continue" "Could not copy backup ${FILE} to remote node ${NODE}"

    # Continue successfully
    log "Successfully copied ${FILE} to remote node ${NODE}"
    continue

  done

}

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Parse options
while getopts hvbd:r:n:f:p: OPTION
do
  case ${OPTION} in
    h)
      usage ;;
    v)
      VERBOSE="true" ;;
    d)
      DATABASE="${OPTARG}" ;;
    b)
      BACKUP="true" ;;
    r)
      RESTORE="${OPTARG}" ;;
    n)
      NODES="${OPTARG}" ;;
    f)
      DESTINATION_DIR="${OPTARG}" ;;
    p)
      PASSWORD="${OPTARG}" ;;
    ?)
      usage ;;
  esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

# Check for backup signal
if [[ "${BACKUP}" = "true" ]]; then

  # Create destination dir
  if [[ ! -e "${DESTINATION_DIR}" ]]; then
    log "Creating ${DESTINATION_DIR} to hold backups"
    mkdir -p ${DESTINATION_DIR}
  fi
  
  # Check if DATABASE has been defined
  if [[ -n "${DATABASE}" ]]; then
    backup_database
  else
    fail_quit 1 "exit" "Please define a database to backup with -d DATABASE"
  fi

fi

# Check if restore file is defined
if [[ -n "${RESTORE}" ]]; then

  # Check if restore file exists
  if [[ ! -e "${RESTORE}" ]]; then
    fail_quit 1 "exit" "File ${RESTORE} does not exist."
  fi

  # Check if DATABASE has been defined
  if [[ -n "${DATABASE}" ]]; then
    restore_database
  else
    fail_quit 1 "exit" "Please define a database to restore with -d DATABASE"
  fi

fi


# Finish script
exit ${EXIT_STATUS}


















