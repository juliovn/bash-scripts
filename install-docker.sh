#!/bin/bash

#%
#% ${SCRIPT_NAME} - installs docker engine
#%
#% usage: ${SCRIPT_NAME} username (to add to docker group)
#%

# Check if user has sudo privileges
if [[ "${UID}" -ne 0 ]]; then
  echo "Please run script with sudo privileges" >&2
  exit 1
fi

# Set the default exit status
EXIT_STATUS=0

# Set variable for script name
SCRIPT_NAME="${0##*/}"

# User to add to docker group
USERNAME="${1}"

# If no params are passed output usage
if [ $# -lt 1 ]; then
	awk -v SCRIPT_NAME="${SCRIPT_NAME}" '/^#%/ {gsub("[$]{SCRIPT_NAME}", SCRIPT_NAME, $0); print substr($0,3)}' $0
	exit 1
fi

# Check if user exists
id -u ${USERNAME}
if [[ "${?}" -ne 1 ]]; then
	echo "${USERNAME} does not exist..." >&2
	exit 1
fi

# Create repo file
cat > /etc/yum.repos.d/docker.repo <<EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# Update yum
yum -y update

# Install docker
yum -y install docker-engine

# Add user to docker group
usermod -a -G docker ${USERNAME}

# Finish script
exit ${EXIT_STATUS}

