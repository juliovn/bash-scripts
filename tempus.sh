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

# Generate ID for logging the task entries
UNIQ_ID=$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c6)

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

# Helper function to get elapsed time from the epochs
function elapsed_time {
    ((h=${1}/3600))
    ((m=(${1}%3600)/60))
    ((s=${1}%60))
    printf "%02d:%02d:%02d\n" $h $m $s
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

    # Output header to log file
    echo "Start, End, Task, Project, ID" >> ${TIMELOG}

    fail_quit "${?}" "exit" "Could not create ${TIMELOG}"
fi

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Start timer function
function start_timer {

    log "Starting timer"

    # Start off with current epoch date
    local start_epoch=$(date "+%s")


}

# Stop timer function
function stop_timer {
    log "Stop timer"
}

# Abort timer function
function abort_timer {
    log "Abort timer"
}

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

# Checks for signals

# Quick check to see if user passed both abort and stop signals
if [[ "${STOP_SIGNAL}" = "true" && "${ABORT_SIGNAL}" = "true" ]]; then
    fail_quit 1 "exit" "Both abort and stop signals passed, please pass only one."
fi

# Check if there is an active task (this will return 1 if so)
COUNT=$(cut -d "," -f 1- ${TIMELOG} | tail -1 | wc -w)

# Stop signal
if [[ "${STOP_SIGNAL}" = "true" ]]; then
    if [[ "${COUNT}" -eq 1 ]]; then
        # There is an active task so we can stop it and log
        stop_timer
    else
        fail_quit 1 "exit" "There is no active timer to stop."
    fi
fi

# Abort signal
if [[ "${ABORT_SIGNAL}" = "true" ]]; then
    if [[ "${COUNT}" -eq 1 ]]; then
        # There is an active timer so we can stop and do not log, as the abort signal was passed
        abort_timer
    else
        fail_quit 1 "exit" "There is not active timer to abort."
    fi
fi

# Finish script
exit ${EXIT_STATUS}






