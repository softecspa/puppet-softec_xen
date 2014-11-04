##########################################################################
# xen class: pacchetti, files e azioni necessarie per un nodo fisico Xen #
##########################################################################
class softec_xen {

  #############
  # Variables #
  #############

  $xen_grubcfg                    = '/boot/grub/menu.lst'
  $xen_dom0_mem_vcpus             = 'dom0_mem=1024M dom0_max_vcpus=1 dom0_vcpus_pin'
  $xen_netloop_nloopbacks         = 'console=tty0 netloop.nloopbacks=0'

  $xen_conf                       = '/etc/xen'
  $xen_scripts                    = '/etc/xen/scripts'

  $xen_file_xend_config           = "${xen_conf}/xend-config.sxp"
  $xen_file_network_bridge_vlan   = "${xen_scripts}/network-bridge-vlan"
  $xen_file_network_multi_vlan    = "${xen_scripts}/network-multi-vlan"
  $xen_logger                     = 'logger -t \'puppet-xen-class\''

  $xen_tools_conf                 = '/etc/xen-tools/xen-tools.conf'
  $apt_preferences                = '/etc/apt/preferences'

  ########
  # Grub #
  ########

  # grub: cambio del valore timeout a 15 secondi
  exec {'xen-grub-timeout':
    command => "sed -r -i.puppet 's/^(timeout[[:space:]]{1,})[0-9][0-9]?/# next line changed by Puppet\\n\\115/g' ${xen_grubcfg}",
    unless  => "egrep '^timeout[[:space:]]{1,}15' ${xen_grubcfg}",
  }

  # grub: commento hiddenmenu, si rende  visibile il menu' di grub
  exec {'xen-grub-hiddenmenu':
    command => "sed -r -i.puppet 's/^(hiddenmenu)/# next line commented by Puppet\\n#\\1/g' ${xen_grubcfg}",
    unless  => "egrep '^#hiddenmenu' ${xen_grubcfg}",
  }

  # grub: xenkopt=console=tty0 netloop.nloopbacks=0 - si indica che il bridge non dovra' utilizzare il loopback
  exec {'xen-grub-nloopbacks':
    command => "sed -r -i.puppet 's/^#[[:space:]]{1,}xenkopt=([[:space:]]?.+)/# xenkopt=${xen_netloop_nloopbacks}/g' ${xen_grubcfg}",
    unless  => "egrep '^#[[:space:]]{1,}xenkopt=${xen_netloop_nloopbacks}' ${xen_grubcfg}",
  }

  # grub: xenkopt=console=tty0 netloop.nloopbacks=0 - si indica che il bridge non dovra' utilizzare il loopback - bug/problema grub-update
  exec {'xen-grub-kernel-nloopbacks':
    command => "sed -r -i.puppet 's#(^module[[:space:]]{1,}/vmlinuz-.+-xen.+ro)(.+)?#\\1 ${xen_netloop_nloopbacks}#g' ${xen_grubcfg}",
    unless  => "egrep '^module[[:space:]]{1,}/vmlinuz-.*${xen_netloop_nloopbacks}$' ${xen_grubcfg}",
  }

  ########
  # Exec #
  ########

  # grub: update
  #  - per il momento lo lego solo a due exec che modificano parametri importanti del kernel
  exec { 'xen-update-grub':
    subscribe   => Exec['xen-grub-kernel-nloopbacks'],
    refreshonly => true,
    command     => "${xen_logger} exec \"update-grub\" && DEBIAN_FRONTEND=noninteractive update-grub",
  }

  ############
  # Packages #
  ############

  package {
    'bridge-utils'      : ensure => present;
    'nfs-common'        : ensure => present;
    'open-iscsi'        : ensure => present;
    'ubuntu-xen-server' : ensure => present;
    'vlan'              : ensure => present;
    'xen-shell'         : ensure => present;
  }

  ################
  # Static files #
  ################

  # push del file "${xen_file_xend_config}" necessario a Xen per definire il networking
  file { $xen_file_xend_config:
    ensure          => present,
    mode            => '0644',
    owner           => 'root',
    group           => 'root',
    source          => 'puppet:///modules/xen/network/xend-config.sxp',
    require         => [
      Package['ubuntu-xen-server'],
      Package['bridge-utils'],
      Package['vlan'],
    ],
  }

  # push del file "${xen_file_network_bridge_vlan}" necessario a Xen per gestire il networking
  file { $xen_file_network_bridge_vlan:
    ensure          => present,
    mode            => '0755',
    owner           => 'root',
    group           => 'root',
    source          => 'puppet:///modules/xen/network/network-bridge-vlan',
    require         => [
      Package['ubuntu-xen-server'],
      Package['bridge-utils'],
      Package['vlan'],
    ],
  }

  # push del file "${xen_file_network_multi_vlan}" necessario a Xen per gestire il networking
  file { $xen_file_network_multi_vlan:
    ensure          => present,
    mode            => '0755',
    owner           => 'root',
    group           => 'root',
    source          => 'puppet:///modules/xen/network/network-multi-vlan',
    require         => File[$xen_file_network_bridge_vlan],
  }

  # exec relativa al file "${xen_file_network_multi_vlan}"
  exec { 'xen_network_update':
    require     => File[$xen_file_network_bridge_vlan],
    subscribe   => File[$xen_file_network_multi_vlan],
    refreshonly => true,
    command     => "${xen_file_network_multi_vlan} start && ${xen_logger} \"${xen_file_network_multi_vlan} start\"",
  }

  # push del file "${xen_tools_conf}": contiene dei custom default relativi al comando xen-create-image
  #  necessario per creare facilmente una nuova virtual machine Ubuntu 8.04
  file { $xen_tools_conf:
    ensure          => present,
    mode            => '0644',
    owner           => 'root',
    group           => 'root',
    source          => 'puppet:///modules/xen/tools/xen-tools.conf',
    require         => Package['ubuntu-xen-server'],
  }
}
