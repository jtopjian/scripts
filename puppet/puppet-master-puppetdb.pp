# == Puppet Master Recipe
#
# This recipe will install a full Puppet Master stack:
# - Puppet Master service
# - An agent of this service
# - Configured to use Passenger
# - Dashboard service using Passenger and MySQL
# - PuppetDB using default Java DB
# - Dashboard pruning
#
# It would be nice to use PostgreSQL for PuppetDB
# but until the dashboard has better pgsql support,
# I don't feel like running both mysql and pgsql.
#
# === Requires:
# - puppetlabs/mysql
# - puppetlabs/apt
# - git: jamtur01/puppet-httpauth
# - git: jtopjian/puppetlabs-apache -b jtopjian-mods
# - git: puppetlabs/puppetlabs-passenger 
# - git: jtopjian/puppetlabs-puppet -b jtopjian-mods
# - git: jtopjian/puppetlabs-dashboard
# - git: puppetlabs/puppetlabs-concat
# - git: example42/puppet-puppetdb
# - git: example42/puppi
#
# === Shortcut
#
# cd /etc/puppet/modules
# puppet module install puppetlabs/mysql
# puppet module install puppetlabs/apt
# puppet module install puppetlabs/stdlib
# git clone https://github.com/jtopjian/puppetlabs-apache apache
# git clone https://github.com/jtopjian/puppetlabs-puppet puppet -b jtopjian-mods
# git clone https://github.com/jamtur01/puppet-httpauth
# git clone https://github.com/jtopjian/puppetlabs-apache apache -b jtopjian-mods
# git clone https://github.com/puppetlabs/puppetlabs-passenger passenger
# git clone https://github.com/jtopjian/puppetlabs-dashboard dashboard
# git clone https://github.com/puppetlabs/puppetlabs-concat concat
# git clone https://github.com/example42/puppet-puppetdb puppetdb
# git clone https://github.com/example42/puppi puppi

class { 'puppet-master': 
  puppet_dashboard_user        => 'puppet-dashboard',
  puppet_dashboard_password    => 'password',
  puppet_dashboard_site        => $::fqdn,
  puppet_storeconfigs_password => 'password',
}

class puppet-master (
  $puppet_dashboard_user,
  $puppet_dashboard_password,
  $puppet_dashboard_site,
  $puppet_storeconfigs_password
) {

  # Add Puppet apt repo
  apt::source { 'puppet':
    location   => 'http://apt.puppetlabs.com',
    release    => $::lsbdistcodename,
    repos      => 'main',
    key        => '4BD6EC30',
    key_server => 'subkeys.pgp.net',
  }

  # Install activerecord
  package { 'activerecord':
    provider => gem,
    ensure   => '3.0.11',
  }

  # Install ruby mysql library
  package { 'libmysql-ruby':
    ensure => present,
  }

  # Make sure the apt repo is added before puppet is configured
  Apt::Source['puppet'] -> Class['puppet']

  # Configure Puppet + passenger + dashboard
  class { 'puppet':
    master                  => true,
    agent                   => true,
    autosign                => true,
    puppet_passenger        => true,
    storeconfigs            => true,
    storeconfigs_dbadapter  => 'puppetdb',
    dashboard               => true,
    dashboard_user          => $puppet_dashboard_user,
    dashboard_password      => $puppet_dashboard_password,
    dashboard_db            => 'puppet_dashboard',
    dashboard_site          => $puppet_dashboard_site,
    dashboard_passenger     => true,
    # PuppetDB takes over 8080
    dashboard_port          => '8888',
  }

  # Configure the database
  class { 'mysql::server': }
  class { 'dashboard::db::mysql': 
    db_name     => 'puppet_dashboard',
    db_user     => $puppet_dashboard_user,
    db_password => $puppet_dashboard_password,
  }

  # Configure dashboard workers
  file { '/etc/default/puppet-dashboard-workers':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['dashboard'],
    content => "# IMPORTANT: Be sure you have checked the values below, appropriately
# configured 'config/database.yml' in your DASHBOARD_HOME, and
# created and migrated the database.

DASHBOARD_HOME=/usr/share/puppet-dashboard
DASHBOARD_USER=puppet-dashboard
DASHBOARD_IFACE=0.0.0.0

START=yes

#  Number of dashboard workers to start.  This will be the number of jobs that
#  can be concurrently processed.  A simple recommendation would be to start
#  with the number of cores you have available.
NUM_DELAYED_JOB_WORKERS=2
",
  }

  service { 'puppet-dashboard-workers':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => File['/etc/default/puppet-dashboard-workers'],
  }


  # Configure pruning
  file { '/usr/share/puppet-dashboard/prune.sh':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => Package['puppet-dashboard'],
    content => "#!/bin/sh
cd /usr/share/puppet-dashboard
/usr/bin/rake RAILS_ENV=production reports:prune upto=1 unit=mon
find /var/lib/puppet/reports -ctime +30 -type f -delete
",
  }

  cron { 'dashboard-prune':
    command => '/usr/share/puppet-dashboard/prune.sh > /dev/null 2>&1',
    user    => 'root',
    minute  => 0,
    hour    => 0,
  }

  # Fix report permissions
  file { "/var/lib/puppet/reports/${::fqdn}":
    recurse => true,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '6750',
  }

  class { 'puppetdb': }
 
}
