#!/bin/bash
# NAME
# backup-to-device.sh - backup directories and mysql databases to external device.

# DESCRIPTION
# This script copy one or more directories listed into the include.txt file and create a tar archive. Then it copy the archive to external usb device. Supports directories exclusion listed into the exclude.txt file. Also it can backup all databases if https://github.com/alfiosalanitri/backup-mysql is installed.

# INSTALLATION
#- rename include-example.txt to include.txt
#- edit .include.txt with one or more directories (one for line)
#- rename exclude-example.txt to exclude.txt
#- edit .exclude.txt with one or more directories (one for line)

# USAGE
#- `cd /path/to/backup-to-device`
#- `./backup-to-device.sh --device=/dev/sdb1 --destination=/directory/inside/usb-device --include=/path/to/backup-to-device/include.txt --exclude=/path/to/backup-to-device/exclude.txt --db-config=/path/to/backup-mysql-script/.config`
#- N.B. --db-config is optional

# AUTHOR: 
#backup-to-device.sh is written by Alfio Salanitri www.alfiosalanitri.it and are licensed under the MIT License.

#############################################################
# Variables
#############################################################
now=$(date +%d%m%Y-%H%M)
tmp_dir=/tmp/backup-to-device
tmp_files_dir="$tmp_dir/files"
mount_point=/media/backup-to-device
backup_mysql=/usr/local/bin/backup-mysql

#############################################################
# Functions
#############################################################
display_help() {
cat << EOF
-------------
Script Usage:
$(basename $0) [-h] [--device=/dev/sdb1] [--destination=/directory/inside/usb-device] [-include=/file/with/dir/to-backup] [--exclude=/file/with/dir/to-exclude] [-db-config=/path/to/backup-mysql/config-file (required only if backup-mysql script exists)]
-------------
EOF
}

spinner() {
spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r[${spin:$i:1}] $1"
  sleep .1
done
}

clear_on_error() {
if [ -d "$tmp_dir"]; then
	sudo rm -r $tmp_dir
fi
if [ -d "$mount_point"]; then
	sudo rm -r $mount_point
fi
}

check_required_arguments() {
if [ "" == "$2" ]; then
  clear_on_error
  printf "[!] --$1= arguments is required.\n\n"
  display_help
  exit 1
fi
}

is_valid_device() {
check_device=$(ls -l /dev/disk/by-path/ | grep usb | grep $(basename $1))
if [ "" == "$check_device" ]; then
  clear_on_error
  printf "[!] -Sorry but $1 isn't a valid usb device.\n\n"
  exit 1
fi
}

check_file() {
if [ ! -f "$1" ]; then
  clear_on_error
  printf "[!] The file $1 doesn't exists.\n\n"
  exit 1
fi
}
check_required_package() {
if ! command -v $1 &> /dev/null; then
	printf "[!] Sorry, but ${1} is required. Install it with apt install $1.\n"
	exit 1;
fi
}
#############################################################
# Get options
#############################################################
while getopts 'h-:' option; do
	case "${option}"
		in
		h)
			display_help
			exit 1
			;;			
		-)
  			case ${OPTARG} in
  				"device"=*) device=$(echo ${OPTARG} | sed -e 's/device=//g');;
  				"destination"=*) destination=$(echo ${OPTARG} | sed -e 's/destination=//g');;
  				"include"=*) include_from=$(echo ${OPTARG} | sed -e 's/include=//g');;
  				"exclude"=*) exclude_from=$(echo ${OPTARG} | sed -e 's/exclude=//g');;
  				"db-config"=*) db_config=$(echo ${OPTARG} | sed -e 's/db-config=//g');;
            esac
			;;
	esac
done
shift "$(($OPTIND -1))"

# check required packages
check_required_package rsync
check_required_package tar

# check required arguments
check_required_arguments 'device' $device
check_required_arguments 'destination' $destination
check_required_arguments 'include' $include_from
check_required_arguments 'exclude' $exclude_from

# check if hard disk is a valid mount point
is_valid_device $device

printf "Backup start!\n"

# ok now create mount point and mount the device
sudo mkdir -p $mount_point
sudo mount $device $mount_point > /dev/null 2>&1 & pid=$!
spinner "Device mounting..."
printf "\n"
mount_dir=$(lsblk -p | grep part | grep $device | awk '{print $7}')
if [ "" == "$mount_dir" ]; then
  clear_on_error
  echo "[!] Device mount failed!"
  exit 1
fi
printf "[+] Device mounted.\n\n"

# remove final slash
mount_dir=${mount_dir%/}

# check if destination directory exists inside hard disk
if [ ! -d "${mount_dir}${destination}" ]; then
  echo "[!] ${mount_dir}${destination} directory not exists inside this device. Create it before or change destination."
  clear_on_error
  exit 1
fi

# check if include and exclude files exists.
check_file $include_from
check_file $exclude_from

# create tmp directory
mkdir -p $tmp_files_dir

# backup mysql databases if bash script exist
if command -v $backup_mysql &>/dev/null; then
  check_required_arguments 'db-config' $db_config
  check_file $db_config
  $backup_mysql $db_config $tmp_files_dir > /dev/null 2>&1 & pid=$!
	spinner "Backup mysql databases..."
  printf "\n[+] Backup mysql databases completed.\n\n"
fi

# backup files
rsync -zarhL --relative --stats --exclude-from="$exclude_from" --files-from="$include_from" / $tmp_files_dir > /dev/null 2>&1 & pid=$!
spinner "Sync directories..."
printf "\n[+] Sync directories completed.\n\n"

# compress tmp directory
tar cf "$tmp_dir/backup-pc-$now.tar" "$tmp_files_dir" > /dev/null 2>&1 & pid=$!
spinner "Compressing temporary directory..."
sudo rm -r $tmp_files_dir
printf "\n[+] Temporary directory compressed.\n\n"

# copy tar archive to hard disk
cp $tmp_dir/backup-pc* ${mount_dir}${destination} & pid=$!
spinner "Copying backup file to device..."
sudo rm -r $tmp_dir
printf "\n[+] Backup file copied.\n\n"

# unmount
sudo umount $device & pid=$!
spinner "Umounting device..."
sudo rm -r $mount_point
printf "\n[+] Device umounted.\n\n"
printf "Backup end with success!\n\n"
exit 1