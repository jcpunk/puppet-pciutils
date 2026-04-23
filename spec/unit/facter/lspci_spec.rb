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

  context 'when both lspci executions return empty output' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D',
                                                               anything).and_return('')
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmmn -k -b -D',
                                                               anything).and_return('')
    end

    it { expect(fact.value).to eq(nil) }
  end

  context 'with a device that has no optional fields' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D',
                                                               anything).and_return(File.read('spec/examples/minimal.lspci.vmm'))
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmmn -k -b -D',
                                                               anything).and_return(File.read('spec/examples/minimal.lspci.vmmn'))
    end

    let(:slot) { fact.value['by_name']['Ethernet controller']['Acme Corp']['0000:00:02.0'] }

    it 'includes mandatory name fields' do
      expect(slot).to include(
        'Class'  => 'Ethernet controller',
        'Device' => 'Fast Ethernet Adapter',
        'Vendor' => 'Acme Corp',
      )
    end

    it 'includes mandatory hex ID fields' do
      expect(slot).to include(
        'ClassID'  => '0200',
        'DeviceID' => '1234',
        'VendorID' => 'abcd',
      )
    end

    it 'omits optional fields when absent' do
      expect(slot.keys).not_to include('SVendor', 'SDevice', 'SVendorID', 'SDeviceID',
                                       'Driver', 'Module', 'Rev', 'PhySlot', 'ProgIf')
    end

    it 'populates by_id from vmmn data' do
      expect(fact.value['by_id']).to eq('abcd' => { '1234' => ['0000:00:02.0'] })
    end

    it 'populates installed_classes_by_id' do
      expect(fact.value['installed_classes_by_id']).to eq(['0200'])
    end

    it 'populates installed_devices_by_id' do
      expect(fact.value['installed_devices_by_id']).to eq(['abcd.1234'])
    end

    it 'populates installed_vendors_by_id' do
      expect(fact.value['installed_vendors_by_id']).to eq(['abcd'])
    end
  end

  context 'when only vmm output is available (vmmn empty)' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D',
                                                               anything).and_return(File.read('spec/examples/vmm_only.lspci.vmm'))
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmmn -k -b -D',
                                                               anything).and_return(File.read('spec/examples/vmm_only.lspci.vmmn'))
    end

    it 'returns nil when vmmn is empty (no hex IDs available)' do
      expect(fact.value).to eq(nil)
    end
  end

  context 'when only vmmn output is available (vmm empty)' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D',
                                                               anything).and_return(File.read('spec/examples/vmmn_only.lspci.vmm'))
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmmn -k -b -D',
                                                               anything).and_return(File.read('spec/examples/vmmn_only.lspci.vmmn'))
    end

    it 'populates by_name using hex strings as fallback names' do
      expect(fact.value['by_name'].keys).to contain_exactly('0600', '0200')
    end

    it 'populates by_id from vmmn data' do
      expect(fact.value['by_id']).to eq(
        '8086' => { '29c0' => ['0000:00:01.0'] },
        '1af4' => { '1041' => ['0000:00:02.0'] },
      )
    end

    it 'populates installed_classes_by_id from vmmn data' do
      expect(fact.value['installed_classes_by_id']).to eq(['0200', '0600'])
    end

    it 'populates installed_devices_by_id from vmmn data' do
      expect(fact.value['installed_devices_by_id']).to eq(['1af4.1041', '8086.29c0'])
    end

    it 'populates installed_vendors_by_id from vmmn data' do
      expect(fact.value['installed_vendors_by_id']).to eq(['1af4', '8086'])
    end

    it 'populates installed_devices_by_class_id from vmmn data' do
      expect(fact.value['installed_devices_by_class_id']).to eq(
        '0600' => ['8086.29c0'],
        '0200' => ['1af4.1041'],
      )
    end

    it 'populates installed_vendors_by_class_id from vmmn data' do
      expect(fact.value['installed_vendors_by_class_id']).to eq(
        '0600' => ['8086'],
        '0200' => ['1af4'],
      )
    end
  end

  context 'when vmmn contains uppercase hex IDs' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D',
                                                               anything).and_return(File.read('spec/examples/uppercase_hex.lspci.vmm'))
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmmn -k -b -D',
                                                               anything).and_return(File.read('spec/examples/uppercase_hex.lspci.vmmn'))
    end

    let(:slot) { fact.value['by_name']['SMBus']['Intel Corporation']['0000:00:1f.3'] }

    it 'normalizes ClassID to lowercase' do
      expect(slot['ClassID']).to eq('0c05')
    end

    it 'normalizes VendorID to lowercase' do
      expect(slot['VendorID']).to eq('8086')
    end

    it 'normalizes SVendorID to lowercase' do
      expect(slot['SVendorID']).to eq('1af4')
    end

    it 'normalizes SDeviceID to lowercase' do
      expect(slot['SDeviceID']).to eq('1100')
    end

    it 'uses lowercase keys in by_id' do
      expect(fact.value['by_id']).to eq('8086' => { '2930' => ['0000:00:1f.3'] })
    end

    it 'uses lowercase entries in installed_classes_by_id' do
      expect(fact.value['installed_classes_by_id']).to eq(['0c05'])
    end

    it 'uses lowercase entries in installed_vendors_by_id' do
      expect(fact.value['installed_vendors_by_id']).to eq(['8086'])
    end
  end

  context 'with lspci on libvirt' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('lspci').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).and_call_original
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmm -k -b -D',
                                                               anything).and_return(File.read('spec/examples/libvirt.lspci.vmm'))
      allow(Facter::Core::Execution).to receive(:execute).with('lspci -vmmn -k -b -D',
                                                               anything).and_return(File.read('spec/examples/libvirt.lspci.vmmn'))
    end

    it 'returns all expected top-level keys' do
      expect(fact.value.keys).to contain_exactly(
        'by_id',
        'by_name',
        'installed_classes_by_id',
        'installed_devices_by_id',
        'installed_devices_by_class_id',
        'installed_vendors_by_id',
        'installed_vendors_by_class_id',
      )
    end

    it 'populates by_id correctly' do
      expect(fact.value['by_id']).to eq(
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
      )
    end

    it 'populates by_name correctly' do
      expect(fact.value['by_name']).to eq(
        'Audio device' => {
          'Intel Corporation' => {
            '0000:00:1b.0' => {
              'Class'     => 'Audio device',
              'ClassID'   => '0403',
              'Device'    => '82801I (ICH9 Family) HD Audio Controller',
              'DeviceID'  => '293e',
              'Driver'    => 'snd_hda_intel',
              'Module'    => ['blaster', 'snd_hda_intel'],
              'ProgIf'    => '00',
              'Rev'       => '03',
              'SDevice'   => 'QEMU Virtual Machine',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Intel Corporation',
              'VendorID'  => '8086',
            },
          },
        },
        'Communication controller' => {
          'Red Hat, Inc.' => {
            '0000:03:00.0' => {
              'Class'     => 'Communication controller',
              'ClassID'   => '0780',
              'Device'    => 'Virtio 1.0 console',
              'DeviceID'  => '1043',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'PhySlot'   => '0-3',
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
          },
        },
        'Ethernet controller' => {
          'Red Hat, Inc.' => {
            '0000:01:00.0' => {
              'Class'     => 'Ethernet controller',
              'ClassID'   => '0200',
              'Device'    => 'Virtio 1.0 network device',
              'DeviceID'  => '1041',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'PhySlot'   => '0',
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
          },
        },
        'Host bridge' => {
          'Intel Corporation' => {
            '0000:00:00.0' => {
              'Class'     => 'Host bridge',
              'ClassID'   => '0600',
              'Device'    => '82G33/G31/P35/P31 Express DRAM Controller',
              'DeviceID'  => '29c0',
              'Module'    => ['intel_agp'],
              'ProgIf'    => '00',
              'SDevice'   => 'QEMU Virtual Machine',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Intel Corporation',
              'VendorID'  => '8086',
            },
          },
        },
        'ISA bridge' => {
          'Intel Corporation' => {
            '0000:00:1f.0' => {
              'Class'     => 'ISA bridge',
              'ClassID'   => '0601',
              'Device'    => '82801IB (ICH9) LPC Interface Controller',
              'DeviceID'  => '2918',
              'Driver'    => 'lpc_ich',
              'Module'    => ['lpc_ich'],
              'ProgIf'    => '00',
              'Rev'       => '02',
              'SDevice'   => 'QEMU Virtual Machine',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Intel Corporation',
              'VendorID'  => '8086',
            },
          },
        },
        'PCI bridge' => {
          'Red Hat, Inc.' => {
            '0000:00:02.0' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:02.1' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:02.2' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:02.3' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:02.4' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:02.5' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:02.6' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:02.7' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:03.0' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:03.1' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:03.2' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:03.3' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:03.4' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
            '0000:00:03.5' => {
              'Class'     => 'PCI bridge',
              'ClassID'   => '0604',
              'Device'    => 'QEMU PCIe Root port',
              'DeviceID'  => '000c',
              'Driver'    => 'pcieport',
              'Module'    => ['shpchp'],
              'ProgIf'    => '00',
              'SDevice'   => 'Device 0000',
              'SDeviceID' => '0000',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1b36',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
          },
        },
        'SATA controller' => {
          'Intel Corporation' => {
            '0000:00:1f.2' => {
              'Class'     => 'SATA controller',
              'ClassID'   => '0106',
              'Device'    => '82801IR/IO/IH (ICH9R/DO/DH) 6 port SATA Controller [AHCI mode]',
              'DeviceID'  => '2922',
              'Driver'    => 'ahci',
              'Module'    => ['ahci'],
              'ProgIf'    => '01',
              'Rev'       => '02',
              'SDevice'   => 'QEMU Virtual Machine',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Intel Corporation',
              'VendorID'  => '8086',
            },
          },
        },
        'SCSI storage controller' => {
          'Red Hat, Inc.' => {
            '0000:04:00.0' => {
              'Class'     => 'SCSI storage controller',
              'ClassID'   => '0100',
              'Device'    => 'Virtio 1.0 block device',
              'DeviceID'  => '1042',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'PhySlot'   => '0-4',
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
            '0000:07:00.0' => {
              'Class'     => 'SCSI storage controller',
              'ClassID'   => '0100',
              'Device'    => 'Virtio 1.0 SCSI',
              'DeviceID'  => '1048',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'PhySlot'   => '0-7',
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
            '0000:08:00.0' => {
              'Class'     => 'SCSI storage controller',
              'ClassID'   => '0100',
              'Device'    => 'Virtio 1.0 block device',
              'DeviceID'  => '1042',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'PhySlot'   => '0-8',
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
          },
        },
        'SMBus' => {
          'Intel Corporation' => {
            '0000:00:1f.3' => {
              'Class'     => 'SMBus',
              'ClassID'   => '0c05',
              'Device'    => '82801I (ICH9 Family) SMBus Controller',
              'DeviceID'  => '2930',
              'Driver'    => 'i801_smbus',
              'Module'    => ['i2c_i801'],
              'ProgIf'    => '00',
              'Rev'       => '02',
              'SDevice'   => 'QEMU Virtual Machine',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Intel Corporation',
              'VendorID'  => '8086',
            },
          },
        },
        'USB controller' => {
          'Red Hat, Inc.' => {
            '0000:02:00.0' => {
              'Class'     => 'USB controller',
              'ClassID'   => '0c03',
              'Device'    => 'QEMU XHCI Host Controller',
              'DeviceID'  => '000d',
              'Driver'    => 'xhci_hcd',
              'Module'    => ['xhci_pci'],
              'PhySlot'   => '0-2',
              'ProgIf'    => '30',
              'Rev'       => '01',
              'SDevice'   => 'Device 1100',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1b36',
            },
          },
        },
        'Unclassified device [00ff]' => {
          'Red Hat, Inc.' => {
            '0000:05:00.0' => {
              'Class'     => 'Unclassified device [00ff]',
              'ClassID'   => '00ff',
              'Device'    => 'Virtio 1.0 balloon',
              'DeviceID'  => '1045',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'PhySlot'   => '0-5',
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
            '0000:06:00.0' => {
              'Class'     => 'Unclassified device [00ff]',
              'ClassID'   => '00ff',
              'Device'    => 'Virtio 1.0 RNG',
              'DeviceID'  => '1044',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'PhySlot'   => '0-6',
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
          },
        },
        'VGA compatible controller' => {
          'Red Hat, Inc.' => {
            '0000:00:01.0' => {
              'Class'     => 'VGA compatible controller',
              'ClassID'   => '0300',
              'Device'    => 'Virtio 1.0 GPU',
              'DeviceID'  => '1050',
              'Driver'    => 'virtio-pci',
              'Module'    => ['virtio_pci'],
              'ProgIf'    => '00',
              'Rev'       => '01',
              'SDevice'   => 'QEMU',
              'SDeviceID' => '1100',
              'SVendor'   => 'Red Hat, Inc.',
              'SVendorID' => '1af4',
              'Vendor'    => 'Red Hat, Inc.',
              'VendorID'  => '1af4',
            },
          },
        },
      )
    end

    it 'populates installed_classes_by_id correctly' do
      expect(fact.value['installed_classes_by_id']).to eq(
        ['00ff', '0100', '0106', '0200', '0300', '0403', '0600', '0601', '0604', '0780', '0c03', '0c05'],
      )
    end

    it 'populates installed_devices_by_id correctly' do
      expect(fact.value['installed_devices_by_id']).to eq(
        ['1af4.1041', '1af4.1042', '1af4.1043', '1af4.1044', '1af4.1045',
         '1af4.1048', '1af4.1050', '1b36.000c', '1b36.000d',
         '8086.2918', '8086.2922', '8086.2930', '8086.293e', '8086.29c0'],
      )
    end

    it 'populates installed_devices_by_class_id correctly' do
      expect(fact.value['installed_devices_by_class_id']).to eq(
        '00ff' => ['1af4.1044', '1af4.1045'],
        '0100' => ['1af4.1042', '1af4.1048'],
        '0106' => ['8086.2922'],
        '0200' => ['1af4.1041'],
        '0300' => ['1af4.1050'],
        '0403' => ['8086.293e'],
        '0600' => ['8086.29c0'],
        '0601' => ['8086.2918'],
        '0604' => ['1b36.000c'],
        '0780' => ['1af4.1043'],
        '0c03' => ['1b36.000d'],
        '0c05' => ['8086.2930'],
      )
    end

    it 'populates installed_vendors_by_id correctly' do
      expect(fact.value['installed_vendors_by_id']).to eq(['1af4', '1b36', '8086'])
    end

    it 'populates installed_vendors_by_class_id correctly' do
      expect(fact.value['installed_vendors_by_class_id']).to eq(
        '00ff' => ['1af4'],
        '0100' => ['1af4'],
        '0106' => ['8086'],
        '0200' => ['1af4'],
        '0300' => ['1af4'],
        '0403' => ['8086'],
        '0600' => ['8086'],
        '0601' => ['8086'],
        '0604' => ['1b36'],
        '0780' => ['1af4'],
        '0c03' => ['1b36'],
        '0c05' => ['8086'],
      )
    end
  end
end
