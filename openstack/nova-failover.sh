#!/bin/bash

# This will probably need modified for Folsom
#
# It appears that libvirt-bin needs restarted prior
# to launching the failed instances so libvirt can 
# read in the XML configuration files.

if [ $# -ne 2 ]; then
  echo "Usage: nova-failover.sh <failed compute node> <new compute node>"
  exit 1
fi

FAILED=$1
NEW=$2

echo "Checking for active instances that were on $FAILED..."
for i in `mysql nova -B -N -e "select id from instances where host = '$FAILED' and vm_state = 'active'"`; do
  NAME=`mysql nova -B -N -e "select display_name from instances where id = '$i'"`
  echo "Moving $NAME to $NEW"
  mysql nova -e "update instances set host = '$NEW' where id = '$i'"

  echo "Checking for volumes that were attached on $NAME"
  for v in `mysql nova -B -N -e "select id from volumes where instance_id = '$i' and status = 'in-use' and attach_status = 'attached'"`; do
    echo "Disconnecting volume $v from $NAME"
    mysql nova -e "update volumes set instance_id = NULL, mountpoint = NULL, status = 'available', attach_status = 'detached' where id = '$v'"
  done

  echo "Rebooting $NAME on $NEW"
  UUID=`mysql nova -B -N -e "select uuid from instances where id = '$i'"`
  nova reboot $UUID

done
