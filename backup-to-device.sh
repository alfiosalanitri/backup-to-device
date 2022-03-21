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
#- `./backup-to-device.sh --help`

# AUTHOR: 
#backup-to-device.sh is written by Alfio Salanitri www.alfiosalanitri.it and are licensed under the MIT License.

#############################################################
# Variables
#############################################################
now=$(date +%d%m%Y-%H%M)
tmp_dir=/tmp/backup-to-device
tmp_files_dir="$tmp_dir/files"
backup_mysql=/usr/local/bin/backup-mysql
#############################################################
# Functions
#############################################################
display_help() {
cat << EOF
Copyright (C) 2022 by Alfio Salanitri
Website: https://github.com/alfiosalanitri/backup-to-device

Usage: $(basename $0) -d PATH -i FILE -e FILE -c FILE (optional)

Options
-d, --destination         mounted device directory where the backup will be saved
-i, --include             file with directories to backup (one directory for line)
-e, --exclude             file with directories to exclude from backup
-c, --config              config file for https://github.com/alfiosalanitri/backup-mysql/ script (OPTIONAL)
-h, --help                show this help
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

clean_tmp() {
if [ -d "$tmp_dir" ]; then
	sudo rm -r $tmp_dir
fi
}

check_required_arguments() {
if [ "" == "$2" ]; then
  clean_tmp
  echo ""
  echo "-----------------------------------"
  printf "[!] $1 is required.\n"
  echo "-----------------------------------"
  echo ""
  display_help
  exit 1
fi
}

check_file() {
if [ ! -f "$1" ]; then
  clean_tmp
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
while [ $# -gt 0 ] ; do
	case $1 in
    -h | --help) display_help ;;
    -d | --destination) destination=$2 ;;
    -i | --include) include_from=$2 ;;
    -e | --exclude) exclude_from=$2 ;;
    -c | --config) db_config=$2 ;;
	esac
  shift
done

# check required packages
check_required_package rsync
check_required_package tar

# check required arguments
check_required_arguments 'destination' $destination
check_required_arguments 'include' $include_from
check_required_arguments 'exclude' $exclude_from

# start
sudo printf "Backup started!\n"

# check if destination directory exists
if [ ! -d "${destination}" ]; then
  echo "[!] ${destination} directory not exists. Create it before or change destination."
  clean_tmp
  exit 1
fi

# check if include and exclude files exists.
check_file $include_from
check_file $exclude_from

# create tmp directory
mkdir -p $tmp_files_dir

# backup mysql databases if config file option and package exists.
if [ "" != "$db_config" ]; then 
  check_file $db_config
  check_required_package $backup_mysql
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

# check the device free space
backup_size=$(du -s $tmp_dir | awk '{print $1}')
destination_free_space=$(df ${destination} | awk '{print $4}' | tail -n +2)
if [ "$backup_size" -gt "$destination_free_space" ]; then 
  # Copy to user home
  printf "[!] Not enough free space on $destination.\n\n"
  cp $tmp_dir/backup-pc* /home/$USER & pid=$!
  spinner "Copying backup file to /home/$USER..."
  printf "\n[+] Backup file copied.\n\n"
else
  # copy tar archive to hard disk
  cp $tmp_dir/backup-pc* ${destination} & pid=$!
  spinner "Copying backup file to device..."
  printf "\n[+] Backup file copied.\n\n"
fi

# End
printf "Backup completed!\n\n"
clean_tmp
exit 1