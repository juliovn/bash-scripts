# Collection of bash scripts

Usage statements for every script here can be accessed by running the script without any arguments or options as in:

`./mysql-backup.sh`

Some exceptions to that rule can be accessed via -h (for help) as in:

`./create-iso-from-cdrom.sh -h`

All scripts are WIP as they can all be improved of course, but some are marked as such only to denote they are literally not functional yet

### skeleton.sh
Skeleton script (logging, custom exit function, option parsing, sudo privileges)

### install-docker.sh
Install docker (yum)

### poor-mans-nagios.sh
Resource monitoring script, for now can only monitor hosts (by ping) and web domains (by curl), also sends emails if resources are down

### mysql-backup.sh
Utility script to perform backup/restore of mysql databases

### trash.sh
Simulates trash bin behaviour, files are moved to trash directory and can be cleaned up at a later time (substitutes `rm -rf`)

### tempus.sh
Time tracking utility for the command line

### watchdog.sh - WIP
Service monitoring script - files inside watchdog/ directory

### create-iso-from-cdrom.sh
Script to extract cdrom device into .iso file

### find-bots.sh
Find IPs from apache log with a lot of hits (count, IP and location)

### lamp-stack-setup.sh - WIP
Automated installation of LAMP stack (yum)
