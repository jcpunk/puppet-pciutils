# @summary Manage pciutils package
#
# This class ensures the `pciutils` package is present (or absent) on the system.
# It accepts a list of package names to allow variations across platforms and an ensure
# value that follows the standard Puppet package `ensure` semantics.
#
# @param package_names Packages to manage
# @param package_ensure Package ensure parameter
#
# @example
#   include pciutils
#
#   class { 'pciutils': }
#
#   class { 'pciutils':
#     package_names  => ['pciutils', 'pciutils-extra'],
#     package_ensure => 'present',
#   }
class pciutils (
  Array[String[1]] $package_names = ['pciutils'],
  Stdlib::Ensure::Package $package_ensure = 'present',
) {
  package { $package_names:
    ensure => $package_ensure,
  }
}
