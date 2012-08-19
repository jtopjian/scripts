#!/bin/bash

apt-get update
apt-get install -y git rake vim puppet apt-cacher-ng

cat <<EOF > /etc/hosts
127.0.0.1 localhost
127.0.1.1 puppet.example.com puppet
EOF
echo puppet > /etc/hostname
hostname -F /etc/hostname

gem install puppet-module
cd /etc/puppet/modules
puppet module install puppetlabs/mysql
puppet module install puppetlabs/apt
puppet module install puppetlabs/stdlib
puppet module install puppetlabs/firewall
git clone https://github.com/jtopjian/puppetlabs-puppet puppet -b jtopjian-mods
git clone https://github.com/jamtur01/puppet-httpauth
git clone https://github.com/jtopjian/puppetlabs-apache apache -b jtopjian-mods
git clone https://github.com/puppetlabs/puppetlabs-passenger passenger
git clone https://github.com/jtopjian/puppetlabs-dashboard dashboard
git clone https://github.com/puppetlabs/puppetlabs-concat concat
git clone https://github.com/jtopjian/puppetlabs-openstack openstack -b jtopjian-mods2
cd openstack
rake modules:clone

cd /etc/puppet/manifests
wget https://raw.github.com/jtopjian/scripts/master/puppet/puppet-master.pp
wget https://raw.github.com/jtopjian/scripts/master/puppet/openstack-nodes.pp -O site.pp

echo 'Acquire::http { Proxy "http://puppet.example.com:3142"; };' > /etc/apt/apt.conf.d/02proxy
