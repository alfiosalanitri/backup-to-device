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
- `./backup-to-device.sh --help`

# TIPS
## How to create a desktop icon application launcher?
If you want launch the backup from GUI:
- rename backup-to-device.desktop.example to backup-to-device.desktop
- edit the file and change Exec line with your path and Icon Line
- `sudo cp backup-to-device.desktop /usr/share/applications`
- `sudo chown root:root /usr/share/applications`

# AUTHOR: 
backup-to-device.sh is written by Alfio Salanitri www.alfiosalanitri.it and are licensed under the MIT License.
