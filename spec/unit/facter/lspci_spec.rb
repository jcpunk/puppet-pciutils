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

    it { expect(fact.value).to eq(nil) }
  end

  context 'with lspci on libvirt' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D', anything).and_return(File.read('spec/examples/libvirt.lspci.vmm'))
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmmn -k -b -D', anything).and_return(File.read('spec/examples/libvirt.lspci.vmmn'))
    end

    it {
      expect(fact.value).to eq(
        {
          'by_id' => {
            '1af4' => {
              '1041' => ['0000:01:00.0'],
              '1042' => ['0000:04:00.0', '0000:08:00.0'],
              '1043' => ['0000:03:00.0'],
              '1044' => ['0000:06:00.0'],
              '1045' => ['0000:05:00.0'],
              '1048' => ['0000:07:00.0'],
              '1050' => ['0000:00:01.0'],
            },
            '1b36' => {
              '000c' => ['0000:00:02.0', '0000:00:02.1', '0000:00:02.2', '0000:00:02.3',
                         '0000:00:02.4', '0000:00:02.5', '0000:00:02.6', '0000:00:02.7',
                         '0000:00:03.0', '0000:00:03.1', '0000:00:03.2', '0000:00:03.3',
                         '0000:00:03.4', '0000:00:03.5'],
              '000d' => ['0000:02:00.0'],
            },
            '8086' => {
              '2918' => ['0000:00:1f.0'],
              '2922' => ['0000:00:1f.2'],
              '2930' => ['0000:00:1f.3'],
              '293e' => ['0000:00:1b.0'],
              '29c0' => ['0000:00:00.0'],
            },
          },
          'by_name' => {
            'Audio device' => {
              'Intel Corporation' => {
                '0000:00:1b.0' => {
                  'Device' => '82801I (ICH9 Family) HD Audio Controller',
                  'DeviceID' => '293e',
                  'Driver' => 'snd_hda_intel',
                  'Module' => ['blaster', 'snd_hda_intel'],
                  'ProgIf' => '00',
                  'Rev' => '03',
                  'SDevice' => 'QEMU Virtual Machine',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'Communication controller' => {
              'Red Hat, Inc.' => {
                '0000:03:00.0' => {
                  'Device' => 'Virtio 1.0 console',
                  'DeviceID' => '1043',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'PhySlot' => '0-3',
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'Ethernet controller' => {
              'Red Hat, Inc.' => {
                '0000:01:00.0' => {
                  'Device' => 'Virtio 1.0 network device',
                  'DeviceID' => '1041',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'PhySlot' => '0',
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'Host bridge' => {
              'Intel Corporation' => {
                '0000:00:00.0' => {
                  'Device' => '82G33/G31/P35/P31 Express DRAM Controller',
                  'DeviceID' => '29c0',
                  'Module' => ['intel_agp'],
                  'ProgIf' => '00',
                  'SDevice' => 'QEMU Virtual Machine',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'ISA bridge' => {
              'Intel Corporation' => {
                '0000:00:1f.0' => {
                  'Device' => '82801IB (ICH9) LPC Interface Controller',
                  'DeviceID' => '2918',
                  'Driver' => 'lpc_ich',
                  'Module' => ['lpc_ich'],
                  'ProgIf' => '00',
                  'Rev' => '02',
                  'SDevice' => 'QEMU Virtual Machine',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'PCI bridge' => {
              'Red Hat, Inc.' => {
                '0000:00:02.0' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:02.1' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:02.2' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:02.3' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:02.4' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:02.5' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:02.6' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:02.7' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:03.0' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:03.1' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:03.2' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:03.3' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:03.4' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
                '0000:00:03.5' => {
                  'Device' => 'QEMU PCIe Root port',
                  'DeviceID' => '000c',
                  'Driver' => 'pcieport',
                  'Module' => ['shpchp'],
                  'ProgIf' => '00',
                  'SDevice' => 'Device 0000',
                  'SDeviceID' => '0000',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1b36',
                },
              },
            },
            'SATA controller' => {
              'Intel Corporation' => {
                '0000:00:1f.2' => {
                  'Device' => '82801IR/IO/IH (ICH9R/DO/DH) 6 port SATA Controller [AHCI mode]',
                  'DeviceID' => '2922',
                  'Driver' => 'ahci',
                  'Module' => ['ahci'],
                  'ProgIf' => '01',
                  'Rev' => '02',
                  'SDevice' => 'QEMU Virtual Machine',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'SCSI storage controller' => {
              'Red Hat, Inc.' => {
                '0000:04:00.0' => {
                  'Device' => 'Virtio 1.0 block device',
                  'DeviceID' => '1042',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'PhySlot' => '0-4',
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
                '0000:07:00.0' => {
                  'Device' => 'Virtio 1.0 SCSI',
                  'DeviceID' => '1048',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'PhySlot' => '0-7',
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
                '0000:08:00.0' => {
                  'Device' => 'Virtio 1.0 block device',
                  'DeviceID' => '1042',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'PhySlot' => '0-8',
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'SMBus' => {
              'Intel Corporation' => {
                '0000:00:1f.3' => {
                  'Device' => '82801I (ICH9 Family) SMBus Controller',
                  'DeviceID' => '2930',
                  'Driver' => 'i801_smbus',
                  'Module' => ['i2c_i801'],
                  'ProgIf' => '00',
                  'Rev' => '02',
                  'SDevice' => 'QEMU Virtual Machine',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'USB controller' => {
              'Red Hat, Inc.' => {
                '0000:02:00.0' => {
                  'Device' => 'QEMU XHCI Host Controller',
                  'DeviceID' => '000d',
                  'Driver' => 'xhci_hcd',
                  'Module' => ['xhci_pci'],
                  'PhySlot' => '0-2',
                  'ProgIf' => '30',
                  'Rev' => '01',
                  'SDevice' => 'Device 1100',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'Unclassified device [00ff]' => {
              'Red Hat, Inc.' => {
                '0000:05:00.0' => {
                  'Device' => 'Virtio 1.0 balloon',
                  'DeviceID' => '1045',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'PhySlot' => '0-5',
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
                '0000:06:00.0' => {
                  'Device' => 'Virtio 1.0 RNG',
                  'DeviceID' => '1044',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'PhySlot' => '0-6',
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
            'VGA compatible controller' => {
              'Red Hat, Inc.' => {
                '0000:00:01.0' => {
                  'Device' => 'Virtio 1.0 GPU',
                  'DeviceID' => '1050',
                  'Driver' => 'virtio-pci',
                  'Module' => ['virtio_pci'],
                  'ProgIf' => '00',
                  'Rev' => '01',
                  'SDevice' => 'QEMU',
                  'SDeviceID' => '1100',
                  'SVendor' => 'Red Hat, Inc.',
                  'SVendorID' => '1af4',
                },
              },
            },
          },
          'installed_devices_by_id' => [
            '1af4.1041',
            '1af4.1042',
            '1af4.1043',
            '1af4.1044',
            '1af4.1045',
            '1af4.1048',
            '1af4.1050',
            '1b36.000c',
            '1b36.000d',
            '8086.2918',
            '8086.2922',
            '8086.2930',
            '8086.293e',
            '8086.29c0',
          ],
          'installed_vendors_by_id' => [
            '1af4',
            '1b36',
            '8086',
          ],
        },
      )
    }
  end
end
