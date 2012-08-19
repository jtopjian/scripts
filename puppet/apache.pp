# == Puppet Apache recipes
#
# Just some quick examples for setting up apache via Puppet
#
# == Requires:
# - git: jtopjian/puppetlabs-apache -b jtopjian-mods
#
# === Shortcut
# 
# git clone https://github.com/jtopjian/puppetlabs-apache apache -b jtopjian-mods
# 
class { 'apache': }

apache::vhost { 'example.com':
  priority           => '10',
  port               => '80',
  docroot            => '/home/ubuntu/example.com',
  serveradmin        => 'webmaster@example.com',
  serveraliases      => ['www.example.com'],
  configure_firewall => false,
}

apache::vhost { 'example.com-ssl':
  priority           => '10',
  port               => '443',
  ssl                => true,
  docroot            => '/home/ubuntu/example.com',
  serveradmin        => 'webmaster@example.com',
  serveraliases      => ['www.example.com'],
  configure_firewall => false,
}
