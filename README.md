# pciutils

Install pciutils and provide a fact with the output.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with pciutils](#setup)
    * [What pciutils affects](#what-pciutils-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with pciutils](#beginning-with-pciutils)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module will manage the pciutils package and build a structured fact
with the state of your pcibus, its devices, and their properties.

## Setup

### Beginning with pciutils

Just including the class should be sufficient.

## Usage

```puppet
include pciutils

class { 'pciutils':
  package_ensure => 'absent'
}
```

## Limitations

Targets Linux only

## Development

See the repo linked in `metadata.json`.
