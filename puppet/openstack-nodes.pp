import 'puppet-master.pp'

class base_server {
  ssh_authorized_key { 'cloud':
    ensure => present,
    user   => 'root',
    type   => 'rsa',
    key    => '',
  }

  @@host { $::fqdn:
    ensure          => present,
    ip              => $::ipaddress_eth2,
    host_aliases    => [$hostname],
  }

  Host <<||>>

}

class basic_server inherits base_server {
  class { 'puppet':
    puppet_server => 'puppet.example.com',
  }
}

node 'puppet.example.com' inherits base_server {
  class { 'puppet-master': 
    puppet_dashboard_user        => 'puppet-dashboard',
    puppet_dashboard_password    => 'password',
    puppet_dashboard_site        => $::fqdn,
    puppet_storeconfigs_password => 'password',
  }
}

node 'cloud.example.com' inherits basic_server {
class { 'openstack::controller': 
    public_address       => $::ipaddress_eth1,
    public_interface     => 'eth1',
    private_interface    => 'eth2',
    db_host              => $::ipaddress_eth1,
    mysql_root_password  => 'password',
    allowed_hosts        => ['127.0.0.%', '10.0.0.%'],
    rabbit_password      => 'password',
    keystone_db_password => 'password',
    keystone_admin_token => '12345',
    admin_email          => 'root@localhost',
    admin_password       => 'password',
    nova_db_password     => 'password',
    nova_user_password   => 'password',
    glance_db_password   => 'password',
    glance_user_password => 'password',
    secret_key           => '12345',
    network_manager      => 'nova.network.manager.VlanManager',
    network_config =>
      vlan_start => '100',
    }
  }
}

node 'c01.example.com', 'c02.example.com' inherits basic_server {
  class { 'openstack::nova::compute': 
    internal_address     => $::ipaddress_eth1,
    rabbit_password      => 'password',
    nova_user_password   => 'password',
    libvirt_type         => 'qemu',
    vncproxy_host        => '10.0.0.10',
  }
}
