# Push e gestione dei file .cfg delle vm
#
# Example:
# xen::vmconfig {
#   "vm_name":
#       cpus    => 4,
#       # [..]
#       vif     => [ "vif1", "vif2",... , "vifN" ],
#       # more params...
# }

define softec_xen::vmconfig (
  $cpus         = '',
  $vcpus        = '',
  $kernel       = '',
  $ramdisk      = '',
  $memory       = '',
  $root         = '',
  $disks        = [''],
  $vifs         = [''],
  $on_poweroff  = '',
  $on_reboot    = '',
  $on_crash     = '',
  $extra        = ''
) {

  # default path per il .cfg
  $confpath = "/etc/xen/${name}.cfg"

  # file di configurazione della vm
  file { $confpath:
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('xen/vmconfig.cfg'),
  }

  # symlink per lo start|stop 'automatico' delle vm
  file { "/etc/xen/auto/${name}.cfg":
    ensure  => $confpath,
    mode    => '0777',
    owner   => 'root',
    group   => 'root',
    require => File[$confpath],
  }

}
