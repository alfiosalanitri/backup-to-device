# NAME
backup-to-device.sh - backup directories and mysql databases to external device.

# DESCRIPTION
This script copy one or more directories listed into the include.txt file and create a tar archive. Then it copy the archive to external usb device. Supports directories exclusion listed into the exclude.txt file. Also it can backup all databases if https://github.com/alfiosalanitri/backup-mysql is installed.

# INSTALLATION
- rename include-example.txt to include.txt
- edit .include.txt with one or more directories (one for line)
- rename exclude-example.txt to exclude.txt
- edit .exclude.txt with one or more directories (one for line)

# USAGE
- `cd /path/to/backup-to-device`
- `./backup-to-device.sh --device=/dev/sdb1 --destination=/directory/inside/usb-device --include=/path/to/backup-to-device/include.txt --exclude=/path/to/backup-to-device/exclude.txt --db-config=/path/to/backup-mysql-script/.config`
- N.B. --db-config is optional

# AUTHOR: 
backup-to-device.sh is written by Alfio Salanitri www.alfiosalanitri.it and are licensed under the MIT License.
