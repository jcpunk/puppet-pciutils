# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/lspci'

describe :lspci, type: :fact do
  subject(:fact) { Facter.fact(:lspci) }

  before :each do
    Facter.clear
  end

  context 'with no lspci' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(false)
    end

    it { expect(fact.value).to eq({}) }
  end

  context 'with lspci on libvirt' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D', anything).and_return(File.read('spec/examples/libvirt.lspci.vmm'))
    end

    it {
      expect(fact.value).to eq(
        {
          'by_name' => {
            'Audio device' => {
              'Intel Corporation' => {
                '0000:00:1b.0' => {
                  'DeviceID' => '8c20',
                  'Driver'   => 'snd_hda_intel',
                  'Module'   => 'snd_hda_intel',
                  'Rev'      => '03',
                  'SDevice'  => 'QEMU Virtual Machine',
                  'VendorID' => '8086',
                },
              },
            },
            'Communication controller' => {
              'Red Hat, Inc.' => {
                '0000:03:00.0' => {
                  'DeviceID' => '1100',
                  'Driver'   => 'virtio-pci',
                  'PhySlot'  => '0-3',
                  'Rev'      => '01',
                  'SDevice'  => 'Device 1100',
                  'VendorID' => '1af4',
                },
              },
            },
            'Ethernet controller' => {
              'Red Hat, Inc.' => {
                '0000:01:00.0' => {
                  'DeviceID' => '1000',
                  'Driver'   => 'virtio-pci',
                  'PhySlot'  => '0',
                  'Rev'      => '01',
                  'SDevice'  => 'Device 1100',
                  'VendorID' => '1af4',
                },
              },
            },
            'Host bridge' => {
              'Intel Corporation' => {
                '0000:00:00.0' => {
                  'DeviceID' => '29c0',
                  'SDevice'  => 'QEMU Virtual Machine',
                  'VendorID' => '8086',
                },
              },
            },
            'ISA bridge' => {
              'Intel Corporation' => {
                '0000:00:1f.0' => {
                  'DeviceID' => '8c54',
                  'Driver'   => 'lpc_ich',
                  'Module'   => 'lpc_ich',
                  'Rev'      => '02',
                  'SDevice'  => 'QEMU Virtual Machine',
                  'VendorID' => '8086',
                },
              },
            },
            'PCI bridge' => {
              'Red Hat, Inc.' => {
                '0000:00:02.0' => { 'DeviceID' => '0101', 'Driver' => 'pcieport', 'VendorID' => '1af4' },
                '0000:00:02.1' => { 'DeviceID' => '0101', 'Driver' => 'pcieport', 'VendorID' => '1af4' },
                '0000:00:02.2' => { 'DeviceID' => '0101', 'Driver' => 'pcieport', 'VendorID' => '1af4' },
                '0000:00:02.3' => { 'DeviceID' => '0101', 'Driver' => 'pcieport', 'VendorID' => '1af4' },
                '0000:00:02.4' => { 'DeviceID' => '0101', 'Driver' => 'pcieport', 'VendorID' => '1af4' },
                '0000:00:02.5' => { 'DeviceID' => '0101', 'Driver' => 'pcieport', 'VendorID' => '1af4' },
                '0000:00:02.6' => { 'DeviceID' => '0101', 'Driver' => 'pcieport', 'VendorID' => '1af4' },
              },
            },
            'SATA controller' => {
              'Intel Corporation' => {
                '0000:00:1f.2' => {
                  'DeviceID' => '8c02',
                  'Driver'   => 'ahci',
                  'Module'   => 'ahci',
                  'ProgIf'   => '01',
                  'Rev'      => '02',
                  'SDevice'  => 'QEMU Virtual Machine',
                  'VendorID' => '8086',
                },
              },
            },
            'SCSI storage controller' => {
              'Red Hat, Inc.' => {
                '0000:04:00.0' => {
                  'DeviceID' => '1100',
                  'Driver'   => 'virtio-pci',
                  'PhySlot'  => '0-4',
                  'Rev'      => '01',
                  'SDevice'  => 'Device 1100',
                  'VendorID' => '1af4',
                },
              },
            },
            'SMBus' => {
              'Intel Corporation' => {
                '0000:00:1f.3' => {
                  'DeviceID' => '8c22',
                  'Driver'   => 'i801_smbus',
                  'Module'   => 'i2c_i801',
                  'Rev'      => '02',
                  'SDevice'  => 'QEMU Virtual Machine',
                  'VendorID' => '8086',
                },
              },
            },
            'USB controller' => {
              'Red Hat, Inc.' => {
                '0000:02:00.0' => {
                  'DeviceID' => '1100',
                  'Driver'   => 'xhci_hcd',
                  'PhySlot'  => '0-2',
                  'ProgIf'   => '30',
                  'Rev'      => '01',
                  'SDevice'  => 'Device 1100',
                  'VendorID' => '1af4',
                },
              },
            },
            'Unclassified device [00ff]' => {
              'Red Hat, Inc.' => {
                '0000:05:00.0' => {
                  'DeviceID' => '1102',
                  'Driver'   => 'virtio-pci',
                  'PhySlot'  => '0-5',
                  'Rev'      => '01',
                  'SDevice'  => 'Device 1100',
                  'VendorID' => '1af4',
                },
                '0000:06:00.0' => {
                  'DeviceID' => '1105',
                  'Driver'   => 'virtio-pci',
                  'PhySlot'  => '0-6',
                  'Rev'      => '01',
                  'SDevice'  => 'Device 1100',
                  'VendorID' => '1af4',
                },
              },
            },
            'VGA compatible controller' => {
              'Red Hat, Inc.' => {
                '0000:00:01.0' => {
                  'DeviceID' => '0100',
                  'Driver'   => 'qxl',
                  'Module'   => 'qxl',
                  'Rev'      => '05',
                  'SDevice'  => 'QEMU Virtual Machine',
                  'VendorID' => '1af4',
                },
              },
            },
          },
          'by_id' => {
            '8086' => {
              '29c0' => ['0000:00:00.0'],
              '8c20' => ['0000:00:1b.0'],
              '8c54' => ['0000:00:1f.0'],
              '8c02' => ['0000:00:1f.2'],
              '8c22' => ['0000:00:1f.3'],
            },
            '1af4' => {
              '0100' => ['0000:00:01.0'],
              '0101' => ['0000:00:02.0', '0000:00:02.1', '0000:00:02.2',
                         '0000:00:02.3', '0000:00:02.4', '0000:00:02.5', '0000:00:02.6'],
              '1000' => ['0000:01:00.0'],
              '1100' => ['0000:02:00.0', '0000:03:00.0', '0000:04:00.0'],
              '1102' => ['0000:05:00.0'],
              '1105' => ['0000:06:00.0'],
            },
          },
        },
      )
    }
  end
end
