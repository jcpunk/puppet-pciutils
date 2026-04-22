# frozen_string_literal: true

# _Description_
#
# Return lspci data as a structured hash with two trees:
#   by_name: Class (human) -> Vendor (human) -> Slot -> props
#            - Uses human-readable names wherever lspci provides them
#            - Includes hex IDs as properties (VendorID, DeviceID, etc.)
#
#   by_id:   vendor_hex -> device_hex -> [slots]
#            - Uses hex codes for matching drivers/hardware
#
# Built from two lspci invocations:
#   - lspci -vmm: human-readable Class, Vendor names, Device descriptions
#   - lspci -vmmn: hex codes for Class, Vendor, Device, SVendor, SDevice
#
# Slots uniquely identify devices and serve as the cross-reference anchor.
Facter.add(:lspci) do
  confine kernel: 'Linux'

  # Recursively sort all keys in nested hashes
  # Returns new hash with keys sorted at all levels
  def sort_hash_deep(hash)
    return hash unless hash.is_a?(Hash)

    hash.sort.to_h do |key, value|
      [key, sort_hash_deep(value)]
    end
  end

  # Parse lspci output into slot-indexed blocks
  # Returns: { "slot" => { "key" => value_or_array, ... }, ... }
  def parse_lspci_blocks(output)
    return {} if output.nil? || output.empty?

    blocks = {}
    current_block = {}
    current_slot = nil

    output.each_line do |line|
      line = line.chomp

      # Blank line = end of block
      if line.empty?
        if current_slot && current_block.any?
          blocks[current_slot] = current_block
        end
        current_block = {}
        current_slot = nil
        next
      end

      # Parse key:value pair (handles both tab and space separators)
      key, value = line.split(':', 2)
      next if value.nil?

      value = value.strip

      # Track slot for indexing
      if key == 'Slot'
        current_slot = value
        current_block = {}
      end

      # Handle multi-valued fields (like Module) - convert to array
      if current_block.key?(key)
        # Convert to array if not already
        current_block[key] = [current_block[key]] unless current_block[key].is_a?(Array)
        current_block[key] << value
      else
        current_block[key] = value
      end
    end

    # Flush final block if file doesn't end with blank line
    if current_slot && current_block.any?
      blocks[current_slot] = current_block
    end

    blocks
  end

  setcode do
    next {} unless Facter::Core::Execution.which('lspci')

    # Parse both outputs into intermediate hashes indexed by slot
    by_slot_vmm = parse_lspci_blocks(
      Facter::Core::Execution.execute('lspci -vmm -k -b -D', on_fail: nil) || '',
    )
    by_slot_vmmn = parse_lspci_blocks(
      Facter::Core::Execution.execute('lspci -vmmn -k -b -D', on_fail: nil) || '',
    )

    # Graceful degradation: return empty if both calls failed
    return {} if by_slot_vmm.empty? && by_slot_vmmn.empty?

    by_name = {}
    by_id   = {}

    # Union of slots from both outputs (gracefully handles missing data)
    all_slots = (by_slot_vmm.keys | by_slot_vmmn.keys)

    all_slots.each do |slot|
      vmm = by_slot_vmm[slot] || {}
      vmmn = by_slot_vmmn[slot] || {}

      # Extract keys for by_name tree structure
      # Prefer human-readable from vmm, fallback to vmmn (which may be hex)
      class_human = vmm['Class'] || vmmn['Class']
      vendor_human = vmm['Vendor'] || vmmn['Vendor']

      # Skip if we can't identify the device
      next unless class_human && vendor_human

      # Extract hex IDs (prefer vmmn, fallback to vmm)
      device_hex = vmmn['Device'] || vmm['Device']
      vendor_hex = vmmn['Vendor'] || vmm['Vendor']
      svendor_hex = vmmn['SVendor'] || vmm['SVendor']
      sdevice_hex = vmmn['SDevice'] || vmm['SDevice']

      # Build by_name properties object
      by_name_props = {}

      # Add human-readable fields from vmm (if available)
      by_name_props['Device'] = vmm['Device'] if vmm['Device']
      by_name_props['SVendor'] = vmm['SVendor'] if vmm['SVendor']
      by_name_props['SDevice'] = vmm['SDevice'] if vmm['SDevice']

      # Add hex ID fields
      by_name_props['DeviceID'] = device_hex if device_hex
      by_name_props['SVendorID'] = svendor_hex if svendor_hex
      by_name_props['SDeviceID'] = sdevice_hex if sdevice_hex

      # Add other properties (present in both vmm and vmmn equally)
      # Ensure Module is always an array if present
      ['Driver', 'ProgIf', 'Rev', 'PhySlot'].each do |field|
        value = vmm[field] || vmmn[field]
        by_name_props[field] = value if value
      end

      # Handle Module specially - always array if present
      module_value = vmm['Module'] || vmmn['Module']

      if module_value
        by_name_props['Module'] = Array(module_value).map(&:to_s).sort
      end

      # Populate by_name tree
      by_name[class_human] ||= {}
      by_name[class_human][vendor_human] ||= {}
      by_name[class_human][vendor_human][slot] = by_name_props

      # Populate by_id tree (only if we have hex IDs for both vendor and device)
      next unless vendor_hex && device_hex
      # Normalize to lowercase hex
      vendor_hex_lower = vendor_hex.downcase
      device_hex_lower = device_hex.downcase

      by_id[vendor_hex_lower] ||= {}
      by_id[vendor_hex_lower][device_hex_lower] ||= []
      by_id[vendor_hex_lower][device_hex_lower] << slot
    end

    { 'by_id' => sort_hash_deep(by_id), 'by_name' => sort_hash_deep(by_name) }
  end
end
