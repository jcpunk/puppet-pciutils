# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/lspci'

describe :lspci, type: :fact do
  subject(:fact) { Facter.fact(:lspci) }

  before :each do
    # perform any action that should be run before every test
    Facter.clear
  end

  context 'with no lspci' do
    before :each do
      expect(Facter::Util::Resolution).to receive(:which).with('lspci').and_return(false)
      expect(Facter::Util::Resolution).not_to receive(:exec)
    end

    it {
      expect(fact.value).to eq({})
    }
  end

  context 'with lspci on libvirt' do
    before :each do
      expect(Facter::Util::Resolution).to receive(:which).with('lspci').and_return(true)
      expect(Facter::Util::Resolution).to receive(:exec).with('lspci -vv -mm -k -b -D 2>/dev/null').and_return(File.read('examples/libvirt.lspci'))
    end

    it {
      expect(fact.value).to eq(
        { 'Host bridge' =>
          { 'Intel Corporation' =>
            { '0000:00:00.0' =>
              { 'Device' => '82G33/G31/P35/P31 Express DRAM Controller',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'QEMU Virtual Machine' } } },
          'VGA compatible controller' =>
           { 'Red Hat, Inc.' =>
             { '0000:00:01.0' =>
               { 'Device' => 'QXL paravirtual graphic card',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'QEMU Virtual Machine',
                'Rev' => '05',
                'Driver' => 'qxl',
                'Module' => 'qxl' } } },
          'PCI bridge' =>
           { 'Red Hat, Inc.' =>
             { '0000:00:02.0' => { 'Device' => 'QEMU PCIe Root port', 'Driver' => 'pcieport' },
              '0000:00:02.1' => { 'Device' => 'QEMU PCIe Root port', 'Driver' => 'pcieport' },
              '0000:00:02.2' => { 'Device' => 'QEMU PCIe Root port', 'Driver' => 'pcieport' },
              '0000:00:02.3' => { 'Device' => 'QEMU PCIe Root port', 'Driver' => 'pcieport' },
              '0000:00:02.4' => { 'Device' => 'QEMU PCIe Root port', 'Driver' => 'pcieport' },
              '0000:00:02.5' => { 'Device' => 'QEMU PCIe Root port', 'Driver' => 'pcieport' },
              '0000:00:02.6' => { 'Device' => 'QEMU PCIe Root port', 'Driver' => 'pcieport' } } },
          'Audio device' =>
           { 'Intel Corporation' =>
             { '0000:00:1b.0' =>
               { 'Device' => '82801I (ICH9 Family) HD Audio Controller',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'QEMU Virtual Machine',
                'Rev' => '03',
                'Driver' => 'snd_hda_intel',
                'Module' => 'snd_hda_intel' } } },
          'ISA bridge' =>
           { 'Intel Corporation' =>
             { '0000:00:1f.0' =>
               { 'Device' => '82801IB (ICH9) LPC Interface Controller',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'QEMU Virtual Machine',
                'Rev' => '02',
                'Driver' => 'lpc_ich',
                'Module' => 'lpc_ich' } } },
          'SATA controller' =>
           { 'Intel Corporation' =>
             { '0000:00:1f.2' =>
               { 'Device' =>
                 '82801IR/IO/IH (ICH9R/DO/DH) 6 port SATA Controller [AHCI mode]',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'QEMU Virtual Machine',
                'Rev' => '02',
                'ProgIf' => '01',
                'Driver' => 'ahci',
                'Module' => 'ahci' } } },
          'SMBus' =>
           { 'Intel Corporation' =>
             { '0000:00:1f.3' =>
               { 'Device' => '82801I (ICH9 Family) SMBus Controller',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'QEMU Virtual Machine',
                'Rev' => '02',
                'Driver' => 'i801_smbus',
                'Module' => 'i2c_i801' } } },
          'Ethernet controller' =>
           { 'Red Hat, Inc.' =>
             { '0000:01:00.0' =>
               { 'Device' => 'Virtio network device',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'Device 1100',
                'PhySlot' => '0',
                'Rev' => '01',
                'Driver' => 'virtio-pci' } } },
          'USB controller' =>
           { 'Red Hat, Inc.' =>
             { '0000:02:00.0' =>
               { 'Device' => 'QEMU XHCI Host Controller',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'Device 1100',
                'PhySlot' => '0-2',
                'Rev' => '01',
                'ProgIf' => '30',
                'Driver' => 'xhci_hcd' } } },
          'Communication controller' =>
           { 'Red Hat, Inc.' =>
             { '0000:03:00.0' =>
               { 'Device' => 'Virtio console',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'Device 1100',
                'PhySlot' => '0-3',
                'Rev' => '01',
                'Driver' => 'virtio-pci' } } },
          'SCSI storage controller' =>
           { 'Red Hat, Inc.' =>
             { '0000:04:00.0' =>
               { 'Device' => 'Virtio block device',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'Device 1100',
                'PhySlot' => '0-4',
                'Rev' => '01',
                'Driver' => 'virtio-pci' } } },
          'Unclassified device [00ff]' =>
           { 'Red Hat, Inc.' =>
             { '0000:05:00.0' =>
               { 'Device' => 'Virtio memory balloon',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'Device 1100',
                'PhySlot' => '0-5',
                'Rev' => '01',
                'Driver' => 'virtio-pci' },
              '0000:06:00.0' =>
               { 'Device' => 'Virtio RNG',
                'SVendor' => 'Red Hat, Inc.',
                'SDevice' => 'Device 1100',
                'PhySlot' => '0-6',
                'Rev' => '01',
                'Driver' => 'virtio-pci' } } } },
      )
    }
  end
end
