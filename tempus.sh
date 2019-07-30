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
    echo "${MESSAGE}"
    logger -t "${0}" "${MESSAGE}"
}

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

# Helper function to calculate elapsed time
function elapsed_time {
    local START_TIME="${1}"
    shift
    local END_TIME="${1}"

    local TIME_DIFF=$(expr ${END_TIME} - ${START_TIME})
    ELAPSED_TIME=$(convert_seconds "$TIME_DIFF")
}

# Helper function to convert seconds
function convert_seconds {
    ((h=${1}/3600))
    ((m=(${1}%3600)/60))
    ((s=${1}%60))
    printf "%02d:%02d:%02d\n" $h $m $s
}

# Function that will output usage statement
function usage {
    echo "Usage: ${0} [-tjdaclh] [-s TASK] [-p [PROJECT] ]" >&2
    echo >&2
    echo "This script is a tool to track time spent on tasks" >&2
    echo >&2
    echo "  -s TASK     Will start a new timer for TASK" >&2
    echo "  -p PROJECT  Assign TASK to PROJECT" >&2
    echo "  -t          Display current status of timer" >&2
    echo "  -j          List all projects" >&2
    echo "  -d          Stops current running TASK and save to ${TIMELOG}" >&2
    echo "  -a          Abort current running TASK and don't save to ${TIMELOG}" >&2
    echo "  -c          Cleanup ${TIMELOG} deleting all entries" >&2
    echo "  -l          Displays contents of ${TIMELOG} to screen and formatted" >&2
    echo "  -h          Displays this usage statement" >&2
    exit 1
}

# Check if log file exists otherwise create it
if [[ ! -e "${TIMELOG}" ]]; then
    touch ${TIMELOG}

    # Output header to log file
    echo "START, TASK, PROJECT, END, ID, ELAPSED" >> ${TIMELOG}

    fail_quit "${?}" "exit" "Could not create ${TIMELOG}"
fi

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Start timer function
function start_timer {

    log "Starting timer for ${TASK}..."

    # Start off with current epoch date
    local START_EPOCH=$(date "+%s")

    # Convert epoch to timestamp for log
    local START_TIME=$(date '+%b %d %H:%M:%S' -d @${START_EPOCH})

    # Insert data into log
    echo "${START_TIME}, ${TASK}, ${PROJECT}, " >> ${TIMELOG}

    # Exit script successfully
    exit 0

}

# Stop timer function
function stop_timer {

    # Gather data on current task
    local START_TIME=$(cut -d "," -f 1 ${TIMELOG} | tail -1)
    local TASK=$(cut -d "," -f 2 ${TIMELOG} | tail -1 | sed -e 's/^[ \t]*//')
    local PROJECT=$(cut -d "," -f 3 ${TIMELOG} | tail -1 | sed -e 's/^[ \t]*//')

    # Get current epoch date for start and end time
    local END_EPOCH=$(date "+%s")
    local START_EPOCH=$(date "+%s" -d "${START_TIME}")

    # Convert epoch to timestamp for log
    local END_TIME=$(date '+%b %d %H:%M:%S' -d @${END_EPOCH})

    log "Stopping timer for ${TASK}..."

    # Remove last line from log to re-insert
    sed -i '$ d' ${TIMELOG}

    # Calculate elapsed time to output
    elapsed_time "${START_EPOCH}" "${END_EPOCH}"

    # Output message to screen
    log "Elapsed time for ${TASK} is: ${ELAPSED_TIME}"

    # Insert data into log
    echo "${START_TIME}, ${TASK}, ${PROJECT}, ${END_TIME}, ${UNIQ_ID}, ${ELAPSED_TIME}" >> ${TIMELOG}

    # Exit script successfully
    exit 0
}

# Diplay timelog function
function display_log {

    # This may seem like too small for a function but I am planning more stuff for this one, like calculating total and maybe date ranges

    # Output table
    column -t -s "," ${TIMELOG}

    # Exit succesfully
    exit 0

}

# Function that will display current status of timer
function display_status {

    # Gather data on current task
    local START_TIME=$(cut -d "," -f 1 ${TIMELOG} | tail -1)
    local TASK=$(cut -d "," -f 2 ${TIMELOG} | tail -1 | sed -e 's/^[ \t]*//')
    local PROJECT=$(cut -d "," -f 3 ${TIMELOG} | tail -1 | sed -e 's/^[ \t]*//')

    if check_task_status ; then
        # Get current epoch and convert starting time to epoch
        local END_EPOCH=$(date "+%s")
        local START_EPOCH=$(date "+%s" -d "${START_TIME}")

        # Calculate elapsed time
        elapsed_time "${START_EPOCH}" "${END_EPOCH}"

        # Output result
        log "Current task is ${TASK} and elapsed time is ${ELAPSED_TIME}"

        # Since this is only for display, exit here and dont touch the log
        exit 0
    else
        # Exit script
        log "No active timer."
        exit 0
    fi

}

# Abort timer function
function abort_timer {

    # Get task name just for the output
    local TASK=$(cut -d "," -f 2 ${TIMELOG} | tail -1)

    log "Aborting timer for ${TASK}"

    # Remove last line from log
    sed -i '$ d' ${TIMELOG}

    # Exit successfully
    exit 0
}

# Function that will display all projects on the log
function display_projects {

  # Get list of projects, remove duplicates and some whitespace
  PROJECT_LIST=$(cut -d "," -f 3 ${TIMELOG} | grep -v "Project" | sed -e 's/^[ \t]*//' | sed '/^$/d' | sort | uniq)

  # Display list
  echo "${PROJECT_LIST}"

  # Exit successfully
  exit 0
}

# Function to check if there is an active task
function check_task_status {

    # Check if there is an active task
    # To clarify this is looking for the "End" column and if there a value there
    COUNT=$(cut -d "," -f 4 ${TIMELOG} | tail -1 | wc -w)

    # Check value of count
    if [[ "${COUNT}" -eq 0 ]]; then
        # There is an active timer
        return 0
    else
        return 1
    fi

}

# Parse options
while getopts s:p:tjdaclh OPTION
do
    case ${OPTION} in
        s)
            TASK="${OPTARG}"
            ;;
        p)
            PROJECT="${OPTARG}"
            ;;
        t)
            display_status
            ;;
        j)
            display_projects
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
            display_log
            ;;
        h)
            usage
            ;;

    esac
done

# Shift parameters
shift "$(( OPTIND -1 ))"

# Start timer here
if [[ -n "${TASK}" ]]; then

    # Check to see if there is a current timer to avoid double tasking
    if check_task_status ; then
        CURRENT_TASK=$(cut -d "," -f 2 ${TIMELOG} | tail -1)
        fail_quit 1 "exit" "${CURRENT_TASK} is the current task, please stop that before starting another."
    fi

    start_timer ${PROJECT}
fi

# Checks for signals

# Quick check to see if user passed both abort and stop signals
if [[ "${STOP_SIGNAL}" = "true" && "${ABORT_SIGNAL}" = "true" ]]; then
    fail_quit 1 "exit" "Both abort and stop signals passed, please pass only one."
fi

# Stop signal
if [[ "${STOP_SIGNAL}" = "true" ]]; then

    if check_task_status ; then
        stop_timer
    else
        fail_quit 1 "exit" "There is no active timer to stop."
    fi
fi

# Abort signal
if [[ "${ABORT_SIGNAL}" = "true" ]]; then
    if check_task_status ; then
        abort_timer
    else
        fail_quit 1 "exit" "There is no active timer to abort."
    fi
fi

# Cleanup signal
if [[ "${CLEANUP_SIGNAL}" = "true" ]]; then
  # Get confirmation from user
  read -p "This will remove all data from ${TIMELOG}. Are you sure you want to continue? [y/n] " CONFIRMATION

  if [[ "${CONFIRMATION}" != "y" ]]; then
    fail_quit 1 "exit" "Confirmation not given for cleanup, exiting..."
  fi

  log "Cleanup up ${TIMELOG}..."

  rm -f ${TIMELOG}

  fail_quit "${?}" "exit" "Could not remove ${TIMELOG}"

  log "Done."

  # Exit successfully
  exit 0
fi

# Finish script
exit ${EXIT_STATUS}






