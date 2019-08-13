#!/bin/bash

# This script will perform monitoring of host and web domains and will
# send alerts in case those resources are down

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

# Usage statement
function usage {
  echo >&2
  echo "Usage: ${SCRIPT_NAME} [-d DOMAIN1,DOMAIN2]... [-h HOST1,HOST2]... [-e EMAIL1,EMAIL2]..." >&2
  echo >&2
  echo "This script monitors hosts and website addresses and shoots emails in case of any resources down" >&2
  echo >&2
  echo "  -v           Activate message output" >&2
  echo "  -d  DOMAINS  Will check DOMAINS for html return code" >&2
  echo "  -h  HOSTS    Will check HOSTS and try a ping" >&2
  echo "  -e  EMAILS   Send report to EMAILS in case any resource is down" >&2
  echo >&2
  exit 1
}

# Check domains for http status code function
function check_domains {

	log "Checking domains..."
	log "==================="
	log ""

	for DOMAIN in $(echo "${DOMAINS}" | tr "," "\n"); do

		log "Processing ${DOMAIN}"

		# curl page to test status
		curl --connect-timeout 5 --max-time 10 -s -v --silent --digest -o -u ${DOMAIN} &> /dev/null

		# check error code
		fail_quit "${?}" "continue" "${DOMAIN} is down"

		# if we got here means the page is up
		log "${DOMAIN} is up"

	done

	log ""
}

# Ping hosts to check status function
function check_hosts {

	log "Checking hosts..."
	log "================="
	log ""

	for HOST in $(echo "${HOSTS}" | tr "," "\n"); do

		log "Processing ${HOST}..."

		# ping host
		ping -c 1 ${HOST} &> /dev/null

		# check error code
		fail_quit "${?}" "continue" "${HOST} is down"

		# if we got here means the host is up
		log "${HOST} is up"


	done

	log ""

}

# Send email reports function
function send_reports {
	log "Sending reports..."

	# Loop through email list
	for EMAIL in $(echo "${EMAILS}" | tr "," "\n"); do

		# Define email variables
		local SUBJECT="[${SCRIPT_NAME}] | some resources are DOWN! [${LOG_FILE}]"
		local SENDER="${HOSTNAME}"

		mail -s "${SUBJECT}" -S from=${SENDER} "${EMAIL}" <<EOF
${SCRIPT_NAME} detected some resources are down, here are the contents of the log file:

$(cat ${LOG_FILE})

EOF

	done

}

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Parse options
while getopts vd:h:e: OPTION
do
	case ${OPTION} in
		v) VERBOSE="true" ;;
		d) DOMAINS="${OPTARG}" ;;
		h) HOSTS="${OPTARG}" ;;
		e) EMAILS="${OPTARG}" ;;
		?) usage ;;
	esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

# Check for DOMAINS
if [[ -n "${DOMAINS}" ]]; then
	check_domains
fi

# Check for HOSTS
if [[ -n "${HOSTS}" ]]; then
	check_hosts
fi

# Check for EMAILS
if [[ -n "${EMAILS}" ]]; then
	# If at least one down then send email
	if grep -q "down" ${LOG_FILE}; then
		send_reports
	fi
fi

# Finish script
exit ${EXIT_STATUS}
