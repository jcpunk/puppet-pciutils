# frozen_string_literal: true

# _Description_
#
# Return lspci data as a structured hash with two trees:
#   by_name: Class -> Vendor -> Slot -> props  (human readable, exact lspci strings)
#   by_id:   vendor_hex -> device_hex -> [slots] (for driver/hardware matching)
#
# Both trees are built from a single invocation of lspci -vmm -k -b -D.
# The -vmm flag emits hex IDs for Vendor/Device, human names for Class.
# Slots uniquely identify devices and serve as the cross-reference anchor.
Facter.add(:lspci) do
  confine kernel: 'Linux'

  setcode do
    next {} unless Facter::Core::Execution.which('lspci')

    by_name = {}
    by_id   = {}

    # State for the current device block; reset on blank line
    slot = nil
    klass = nil
    vendor_name = nil
    vendor_hex = nil
    device_hex = nil
    props = {}

    flush = lambda do
      # Only commit if we have the minimum required fields
      if slot && klass && vendor_name && vendor_hex && device_hex
        by_name[klass] ||= {}
        by_name[klass][vendor_name] ||= {}
        by_name[klass][vendor_name][slot] = props.merge(
          'VendorID' => vendor_hex,
          'DeviceID' => device_hex,
        )

        by_id[vendor_hex] ||= {}
        by_id[vendor_hex][device_hex] ||= []
        by_id[vendor_hex][device_hex] << slot
      end

      slot = nil
      klass = nil
      vendor_name = nil
      vendor_hex = nil
      device_hex = nil
      props = {}
    end

    Facter::Core::Execution.execute('lspci -vmm -k -b -D', on_fail: nil).each_line do |line|
      line = line.chomp

      if line.empty?
        flush.call
        next
      end

      key, value = line.split(":\t", 2)
      next if value.nil?
      value = value.strip

      case key
      when 'Slot'   then slot        = value
      when 'Class'  then klass       = value
      when 'Vendor' then vendor_hex  = value
      when 'Device' then device_hex  = value
      when 'SVendor'
        # SVendor is the human-readable vendor name in -vmm output
        vendor_name = value
      else
        props[key] = value
      end
    end

    # Flush final block if file didn't end with a blank line
    flush.call

    { 'by_name' => by_name, 'by_id' => by_id }
  end
end
