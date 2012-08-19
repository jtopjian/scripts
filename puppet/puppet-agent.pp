# == Puppet Agent Recipe
#
# Simple recipe to install a Puppet client.
# The client will be configured to run via cron once per hour.
#
# === Requires
# 
# - git: jtopjian/puppetlabs-puppet
#
# === Shortcut
# git clone https://github.com/jtopjian/puppetlabs-puppet puppet
#

class { 'puppet-agent': 
  server => 'puppet.example.com',
}

class puppet-agent ( $server ) {
  class { 'puppet': puppet_server => $server, }
}
