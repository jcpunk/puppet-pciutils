# @summary Manage pciutils package
#
# Manages the pciutils package
#
# @param package_names Packages to manage
# @param package_ensure Package ensure parameter
#
# @example
#   include pciutils
#
#   class { 'pciutils':
#     package_names  => ['pciutils'],
#     package_ensure => 'absent',
#   }
class pciutils (
  Array[String[1]] $package_names,
  String $package_ensure,
){
  package { $package_names:
    ensure => $package_ensure,
  }
}
