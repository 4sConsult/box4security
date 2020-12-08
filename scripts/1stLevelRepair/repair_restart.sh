#!/bin/bash
set -e
# Log file to use
# Create path if allowed or do NOP
mkdir -p /var/log/box4s/1stLevelRepair || :
LOG_DIR="/var/log/box4s/1stLevelRepair"
if [[ ! -w $LOG_DIR ]]; then
  LOG_DIR="$HOME"
fi

LOG=$LOG_DIR/restart_service.log

# Do not use interactive debian frontend.
export DEBIAN_FRONTEND=noninteractive

# Forward fd2 to the console
# exec 2>&1
# Forward fd1 to $LOG
exec 2>&1 1>>${LOG}
echo -n "Stopping BOX4security Service.. " 1>&2
sudo systemctl stop box4security.service
echo "[ DONE ]" 1>&2
echo -n "Starting BOX4security Service.. " 1>&2
sudo systemctl start box4security.service
echo "[ DONE ]" 1>&2
