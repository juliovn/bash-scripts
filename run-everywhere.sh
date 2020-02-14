#!/bin/bash

# This script will execute commands on multiple servers

### Variable definitions ###
SERVERS="/servers"
EXIT_CODE=0

### Function definitions ###

# log - function that logs messages to standard output and to syslog
function log {
	local MESSAGE="${@}"
	if [[ "${VERBOSE}" = "true" ]]; then
		echo "${MESSAGE}"
	fi
	logger -t "${0}" "${MESSAGE}"
}

# fail_quit - function that will exit the script in case a command fails
function fail_quit {
	CODE="${1}"
	shift
	MESSAGE="${@}"

	if [[ "${CODE}" -ne 0 ]]; then
		echo "${MESSAGE}" >&2
		exit 1
	fi
}

# usage - function that will display usage information
function usage {
	echo "Usage: ${0} [-vns] [-f FILE] COMMAND" >&2
	echo "This script will run COMMAND on all servers contained in ${SERVERS} file" >&2
	echo "	-f FILE	Override default behaviour of pulling servers from ${SERVERS} and use passed FILE instead" >&2
	echo "	-v	See the output and messages" >&2
	echo "	-n	Perform a 'dry run' and list COMMAND that would run on each server" >&2
	echo "	-s	Execute COMMAND with sudo privileges on each server" >&2
	exit 1
}

### Option parsing ###

# Parse options
while getopts vnsf: OPTION
do
	case ${OPTION} in
		v)
			VERBOSE="true"
			;;
		f)
			FILE_OVERRIDE="true"
			FILE="${OPTARG}"
			;;
		n)
			DRY_RUN="true"
			;;
		s)
			SUPER_USER="sudo"
			;;
		?)
			usage
			;;
	esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

### Main shell body ###

# Check if user is root, if true exit the script
if [[ "${UID}" -eq 0 ]]; then
	fail_quit 1 "Please do not run as super user, you can specify the -s option to run the commands as super user"
fi

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Override SERVERS in case a FILE has been passed
if [[ "${FILE_OVERRIDE}" = "true" ]]; then
	if [[ ! -e "${FILE}" ]]; then
		fail_quit 1 "Cannot open file ${FILE}"
	else
		SERVERS="${FILE}"
	fi
fi

# Capture command passed as argument into variable
CMD="${@}"

# Check if user has specified -s for sudo and prepend to command if true
if [[ ! -z "${SUPER_USER}" ]]; then
	CMD="${SUPER_USER} ${@}"
fi

# Loop through server list
for SERVER in $(cat ${SERVERS}); do
	log "Running ${CMD} on ${SERVER}"
	SSH_CMD="ssh -o ConnectTimeout=2"

	# Check if 'dry run' option was selected, if so output commands and server
	if [[ "${DRY_RUN}" = "true" ]]; then
		echo "DRY RUN: ${SSH_CMD} ${SERVER} ${CMD}"
	else
		# Otherwise just execute command
		${SSH_CMD} ${SERVER} ${CMD}

		SSH_EXIT_CODE="${?}"

		if [[ "${SSH_EXIT_CODE}" -ne 0 ]]; then
			echo "ssh command failed for server ${SERVER}"
			EXIT_CODE=${SSH_EXIT_CODE}
		fi
	fi
done

# Finish script
exit ${EXIT_CODE}
