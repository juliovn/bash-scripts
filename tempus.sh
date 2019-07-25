#!/bin/bash


# This script is a tool to track time spent on tasks

### VARIABLES ###

# Default value for exit status
EXIT_STATUS=0

# Timelog file
TIMELOG="$HOME/.timelog"

# Set default value for task name and project name (if user doesn't provide one)
DEFAULT_TASK="Untitled task"
DEFAULT_PROJECT="Untitled project"


# Check if log file exists otherwise create it
if [[ ! -e "${TIMELOG}" ]]; then
	touch ${TIMELOG}
fi

### END OF VARIABLES ###

### UTIL FUNCTIONS ###

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

### END OF UTIL FUNCTIONS ###

