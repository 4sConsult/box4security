#!/bin/bash
set -e
# Log file to use
# Create path if allowed or do NOP
mkdir -p /var/log/box4s/1stLevelRepair || :
LOG_DIR="/var/log/box4s/1stLevelRepair"
if [[ ! -w $LOG_DIR ]]; then
  LOG_DIR="$HOME"
fi

LOG=$LOG_DIR/reset.log

# Do not use interactive debian frontend.
export DEBIAN_FRONTEND=noninteractive

# Forward fd2 to the console
# exec 2>&1
# Forward fd1 to $LOG
exec 2>&1 1>>${LOG}

function delete_If_Exists(){
  # Helper to delete files and directories if they exist
  if [ -d $1 ]; then
    # Directory to remove
    sudo rm $1 -r
  fi
  if [ -f $1 ]; then
    # File to remove
    sudo rm $1
  fi
}
function testNet() {
  # Returns 0 for successful internet connection and dns resolution, 1 else
  ping -q -c 1 -W 1 $1 >/dev/null;
  return $?
}
function waitForNet() {
  # use argument or default value of google.com
  HOST=${1:-"google.com"}
  while ! testNet $HOST; do
    # while testNet returns non zero value
    echo "No internet connectivity or dns resolution of $HOST, sleeping for 15s" 1>&2
    sleep 15s
    echo /etc/resolv.conf | grep 'nameserver' || echo "nameserver 8.8.8.8" > /etc/resolv.conf && echo "Empty /etc/resolv.conf/ -> inserting 8.8.8.8" 1>&2
  done
}
#
#Flags:
# no-recreate: Does not create an empty BOX4security after deleting the current one
#

echo -n "Stopping BOX4security Service.. " 1>&2

if [[ $(systemctl list-units --all -t service --full --no-legend "box4security.service" | cut -f1 -d' ') == $n.service ]]; then
  sudo systemctl stop box4security.service
  #Remove all Docker containers and Volumes
  sudo docker rm -f $(docker ps -a -q) >/dev/null || :
  sudo docker volume rm $(docker volume ls -q) >/dev/null || :
fi
echo "[ DONE ]" 1>&2

echo -n "Removing Data.. " 1>&2
#Securely delete /data
if [ -d /data ]; then
  # Directory to remove
  sudo srm -zr /data
fi
delete_If_Exists /var/lib/box4s
delete_If_Exists /var/lib/postgresql
delete_If_Exists /var/lib/box4s_openvas
delete_If_Exists /var/lib/box4s_suricata_rules
delete_If_Exists /var/lib/box4s_docs
delete_If_Exists /var/lib/elastalert
delete_If_Exists /var/lib/logstash
delete_If_Exists /etc/box4s
delete_If_Exists /tmp/box4s
waitForNet
echo "[ DONE ]" 1>&2

echo -n "Installing new BOX4security.. " 1>&2
curl -sL https://gitlab.com/snippets/1982942/raw | sudo bash
echo "[ DONE ]" 1>&2
