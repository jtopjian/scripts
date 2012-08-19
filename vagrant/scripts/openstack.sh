#!/bin/bash


cat <<EOF > /etc/hosts
127.0.0.1 localhost
127.0.1.1 $1.example.com $1
10.0.0.10 puppet.example.com puppet
EOF
echo $1 > /etc/hostname
hostname -F /etc/hostname

echo 'Acquire::http { Proxy "http://puppet.example.com:3142"; };' > /etc/apt/apt.conf.d/02proxy
apt-get update
apt-get install -y git rake vim puppet

cat <<EOF > /etc/puppet/puppet.conf
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=\$vardir/lib/facter
templatedir=\$confdir/templates
prerun_command=/etc/puppet/etckeeper-commit-pre
postrun_command=/etc/puppet/etckeeper-commit-post
server=puppet.example.com
pluginsync=true
EOF

/usr/sbin/puppetd --onetime --no-daemonize --verbose

