#!/bin/bash


# This script is a tool to track time spent on tasks

# Check if user is root
if [[ "${UID}" -eq 0 ]]; then
    echo "Please do not run the script as root." >&2
    exit 1
fi

# Default value for exit status
EXIT_STATUS=0

# Timelog file
TIMELOG="$HOME/.timelog"

# Function that logs messages to standard output and to syslog
function log {
    local MESSAGE="${@}"
    if [[ "${VERBOSE}" = "true" ]]; then
        echo "${MESSAGE}"
    fi
    logger -t "${0}" "${MESSAGE}"
}

function fail_quit {
	# Error code
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

# Function that will output usage statement
function usage {
    echo "Usage: ${0} [-jdaclh] [-s TASK] [-p [PROJECT] ]" >&2
    echo "This script is a tool to track time spent on tasks" >&2
    echo "  -s TASK     Will start a new timer for TASK" >&2
    echo "  -p PROJECT  Assign TASK to PROJECT" >&2
    echo "  -j          List all projects" >&2
    echo "  -d          Stops current running TASK and save to ${TIMELOG}" >&2
    echo "  -a          Abort current running TASK and don't save to ${TIMELOG}" >&2
    echo "  -c          Cleanup ${TIMELOG} deleting all entries (will be prompted for backup option)" >&2
    echo "  -l          Displays contents of ${TIMELOG} to screen and formatted" >&2
    echo "  -h          Displays this usage statement" >&2
    exit 1
}

# Check if log file exists otherwise create it
if [[ ! -e "${TIMELOG}" ]]; then
    touch ${TIMELOG}

    fail_quit "${?}" "exit" "Could not create ${TIMELOG}"
fi

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Main functions will go here



# Parse options
while getopts s:p:jdaclh OPTION
do
    case ${OPTION} in
        s)
            TASK="${OPTARG}"
            echo "${TASK}"
            ;;
        p)
            PROJECT="${OPTARG}"
            echo "${PROJECT}"
            ;;
        j)
            echo "list projects called"
            ;;
        d)
            STOP_SIGNAL="true"
            ;;
        a)
            ABORT_SIGNAL="true"
            ;;
        c)
            CLEANUP_SIGNAL="true"
            ;;
        l)
            echo "Log function called for"
            ;;
        h)
            usage
            ;;

    esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

# Finish script
exit ${EXIT_STATUS}
