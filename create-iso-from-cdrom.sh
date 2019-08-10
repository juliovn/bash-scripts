#!/bin/bash

# This script will create a .iso file (taken as parameter) from the cdrom device

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# Usage function
function usage {
  echo >&2
  echo "Usage: ${SCRIPT_NAME}" >&2
  echo >&2
  echo "This script created a .iso file from the cdrom device" >&2
  echo >&2
  echo "  -h          Output this message" >&2
  echo "  -f FILE.iso Create a new iso called FILE.iso" >&2
  echo >&2
  exit 1
}

# Main function that will create .iso file
# Takes one arg:
# 1 - filename that will be used to save the file
function create_iso_from_cdrom {

  # Check if isoinfo is available
  if ! command -v isoinfo ; then
    echo "isoinfo command not available, please install before proceeding" >&2
    exit 1
  fi

  local ISO_FILENAME="${1}"

  # Get block size and volume size
  local BLOCK_SIZE=$(isoinfo -d -i /dev/cdrom | grep 'block size' | cut -d ":" -f2 | awk '{$1=$1};1')
  local VOLUME_SIZE=$(isoinfo -d -i /dev/cdrom | grep 'Volume size' | cut -d ":" -f2 | awk '{$1=$1};1')

  echo "Creating ${ISO_FILENAME}..."

  # Create iso file
  dd if=/dev/cdrom of=${ISO_FILENAME} bs=${BLOCK_SIZE} count=${VOLUME_SIZE}

  if [[ "${?}" -ne 0 ]]; then
    echo "Could not extract cdrom into ${ISO_FILENAME}" >&2
    exit 1
  fi

  echo "${ISO_FILENAME} successfully created!"

}

# Parse options
while getopts hf: OPTION
do
  case ${OPTION} in
    h) usage ;;
    f) FILE="${OPTARG}" ;;
    ?) usage ;;
  esac
done

# If no parameters are passed output usage
if [[ "${#}" -lt 1 ]]; then
    usage
fi

# Check if file is empty
if [[ -n "${FILE}" ]]; then
  echo "Please specify the filename destination for the .iso" >&2
  exit 1

else
  create_iso_from_cdrom "${FILE}"
fi

# Finish script
exit 0
