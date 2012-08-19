#!/bin/bash

# This Nagios script was written against version 3.3 of Gluster.  Older
# versions will most likely not work at all with this monitoring script.
#
# Gluster currently requires elevated permissions to do anything.  In order to
# accommodate this, you need to allow your Nagios user some additional
# permissions via sudo.  The line you want to add will look something like the
# following in /etc/sudoers (or something equivalent):
#
# Defaults:nagios !requiretty
# nagios ALL=(root) NOPASSWD:/usr/sbin/gluster peer status,/usr/sbin/gluster volume list,/usr/sbin/gluster volume heal [[\:graph\:]]* info
#
# That should give us all the access we need to check the status of any
# currently defined peers and volumes.

# Credit: http://gluster.org/pipermail/gluster-users/2012-June/010798.html

# define some variables
ME=$(basename -- $0)
SUDO="/usr/bin/sudo"
PIDOF="/bin/pidof"
GLUSTER="/usr/sbin/gluster"
PEERSTATUS="peer status"
VOLLIST="volume list"
VOLHEAL1="volume heal"
VOLHEAL2="info"
peererror=
volerror=

# check for commands
for cmd in $SUDO $PIDOF $GLUSTER; do
  if [ ! -x "$cmd" ]; then
    echo "$ME UNKNOWN - $cmd not found"
    exit 3
  fi
done

# check for glusterd (management daemon)
if ! $PIDOF glusterd &>/dev/null; then
  echo "$ME CRITICAL - glusterd management daemon not running"
  exit 2
fi

# check for glusterfsd (brick daemon)
if ! $PIDOF glusterfsd &>/dev/null; then
  echo "$ME CRITICAL - glusterfsd brick daemon not running"
  exit 2
fi

# get peer status
peerstatus="peers: "
for peer in $(sudo $GLUSTER $PEERSTATUS | grep '^Hostname: ' | awk '{print $2}'); do
  state=
  state=$(sudo $GLUSTER $PEERSTATUS | grep -A 2 "^Hostname: $peer$" | grep '^State: ' | sed -nre 's/.* \(([[:graph:]]+)\)$/\1/p')
  if [ "$state" != "Connected" ]; then
    peererror=1
  fi
  peerstatus+="$peer/$state "
done

# get volume status
volstatus="volumes: "
for vol in $(sudo $GLUSTER $VOLLIST); do
  thisvolerror=0
  entries=
  for entries in $(sudo $GLUSTER $VOLHEAL1 $vol $VOLHEAL2 | grep '^Number of entries: ' | awk '{print $4}'); do
    if [ "$entries" -gt 0 ]; then
      volerror=1
      let $((thisvolerror+=entries))
    fi
  done
  volstatus+="$vol/$thisvolerror unsynchronized entries "
done

# drop extra space
peerstatus=${peerstatus:0:${#peerstatus}-1}
volstatus=${volstatus:0:${#volstatus}-1}

# set status according to whether any errors occurred
if [ "$peererror" ] || [ "$volerror" ]; then
  status="CRITICAL"
else
  status="OK"
fi

# actual Nagios output
echo "$ME $status $peerstatus $volstatus"

# exit with appropriate value
if [ "$peererror" ] || [ "$volerror" ]; then
  exit 2
else
  exit 0
fi
