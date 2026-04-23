# frozen_string_literal: true

# @summary Returns PCI device information from `lspci`.
#
#   The fact runs `lspci -vmm` (human‑readable) and `lspci -vmmn` (hex codes)
#   and builds a multi‑part hash:
#
#   * `by_name` - hierarchical tree keyed by human‑readable class and vendor,
#     ending in a slot hash with the device's properties.
#   * `by_id`   - tree keyed by numeric vendor/device IDs, each leaf being an
#     sorted list of unique slots that match the ID pair.
#   * `installed_classes_by_id` - sorted, deduplicated array of
#     `<class_hex>` strings for all detected devices
#   * `installed_devices_by_id` - sorted, deduplicated array of
#     `<vendor_hex>.<device_hex>` strings for all detected devices.
#   * `installed_devices_by_class_id` - hierarchical tree keyed by class ID,
#     each leaf being a sorted, deduplicated array of device IDs.
#   * `installed_vendors_by_class_id` - hierarchical tree keyed by class ID,
#     each leaf being a sorted, deduplicated array of vendor IDs.
#
# @return [Hash] Structured PCI information with the following keys:
#   * `by_name`                 - `Hash[String => Hash[String => Hash[String => Hash]]]`
#   * `by_id`                   - `Hash[String => Hash[String => Array[String]]]`
#   * `installed_classes_by_id` - `Array[String]`
#   * `installed_devices_by_id` - `Array[String]`
#   * `installed_devices_by_class_id` - `Hash[String => Array[String]]`
#   * `installed_vendors_by_id` - `Array[String]`
#   * `installed_vendors_by_class_id` - `Hash[String => Array[String]]`
#
# @example Sample output (truncated)
#   {
#     "by_name" => {
#       "Ethernet controller" => {
#         "Intel Corporation" => {
#           "0000:00:1f.6" => {
#             "Device"   => "Ethernet Connection I219-LM",
#             "DeviceID" => "15d8",
#             "Driver"   => "e1000e",
#             ...
#           }
#         }
#       }
#     },
#     "by_id" => {
#       "8086" => { "15d8" => ["0000:00:1f.6"] }
#     },
#     "installed_classes_by_id" => ["200"]
#     "installed_devices_by_id" => ["8086.15d8"]
#     "installed_devices_by_class_id" => {
#       "0200" => ["8086.15d8"]
#     },
#     "installed_vendors_by_id" => ["8086"]
#     "installed_vendors_by_class_id" => {
#       "0200" => ["8086"]
#     }
#   }
#
Facter.add(:lspci) do
  confine kernel: 'Linux'

  # Recursively sort all keys in nested hashes
  # Also sorts and dedupes any arrays found
  # Returns new hash with keys sorted at all levels
  def sort_hash_deep(value)
    if value.is_a?(Hash)
      value.sort.to_h do |key, val|
        [key, sort_hash_deep(val)]
      end
    elsif value.is_a?(Array)
      value.uniq.sort
    else
      value
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
    return {} unless Facter::Core::Execution.which('lspci')

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
    installed_classes_by_id = []
    installed_devices_by_id = []
    installed_vendors_by_id = []
    installed_devices_by_class_id = {}
    installed_vendors_by_class_id = {}

    # Union of slots from both outputs (gracefully handles missing data)
    all_slots = (by_slot_vmm.keys | by_slot_vmmn.keys)

    all_slots.each do |slot|
      vmm = by_slot_vmm[slot] || {}
      vmmn = by_slot_vmmn[slot] || {}

      # Extract keys for by_name tree structure
      # Prefer human-readable from vmm, fallback to vmmn (which may be hex)
      class_human = vmm['Class'] || vmmn['Class']
      device_human = vmm['Device'] || vmmn['Device']
      vendor_human = vmm['Vendor'] || vmmn['Vendor']

      # Skip if we can't identify the device
      next unless class_human && vendor_human && device_human

      # Extract hex IDs (prefer vmmn, fallback to vmm)
      class_hex = vmmn['Class'] || vmm['Class']
      device_hex = vmmn['Device'] || vmm['Device']
      vendor_hex = vmmn['Vendor'] || vmm['Vendor']
      svendor_hex = vmmn['SVendor'] || vmm['SVendor']
      sdevice_hex = vmmn['SDevice'] || vmm['SDevice']

      # Build by_name properties object
      by_name_props = {}

      # Add human-readable fields from vmm (if available)
      by_name_props['Class'] = class_human
      by_name_props['Device'] = device_human
      by_name_props['Vendor'] = vendor_human
      by_name_props['SVendor'] = vmm['SVendor'] if vmm['SVendor']
      by_name_props['SDevice'] = vmm['SDevice'] if vmm['SDevice']

      # Add hex ID fields
      by_name_props['ClassID'] = class_hex.downcase
      by_name_props['DeviceID'] = device_hex.downcase
      by_name_props['VendorID'] = vendor_hex.downcase
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
        by_name_props['Module'] = Array(module_value).map(&:to_s).sort.uniq
      end

      # Populate by_name tree
      by_name[class_human] ||= {}
      by_name[class_human][vendor_human] ||= {}
      by_name[class_human][vendor_human][slot] = by_name_props

      # Populate by_id tree (only if we have hex IDs)
      next unless class_hex && vendor_hex && device_hex

      # Normalize to lowercase hex
      class_hex_lower = class_hex.downcase
      device_hex_lower = device_hex.downcase
      vendor_hex_lower = vendor_hex.downcase

      # Setup our lists by_id
      installed_classes_by_id << class_hex_lower
      installed_devices_by_id << "#{vendor_hex_lower}.#{device_hex_lower}"
      installed_vendors_by_id << vendor_hex_lower

      (installed_devices_by_class_id[class_hex_lower] ||= []) << "#{vendor_hex_lower}.#{device_hex_lower}"
      (installed_vendors_by_class_id[class_hex_lower] ||= []) << vendor_hex_lower
      installed_devices_by_class_id[class_hex_lower] = installed_devices_by_class_id[class_hex_lower].sort.uniq
      installed_vendors_by_class_id[class_hex_lower] = installed_vendors_by_class_id[class_hex_lower].sort.uniq

      by_id[vendor_hex_lower] ||= {}
      by_id[vendor_hex_lower][device_hex_lower] ||= []
      by_id[vendor_hex_lower][device_hex_lower] << slot
      by_id[vendor_hex_lower][device_hex_lower] = by_id[vendor_hex_lower][device_hex_lower]
    end

    {
      'by_id'   => sort_hash_deep(by_id),
      'by_name' => sort_hash_deep(by_name),
      'installed_classes_by_id' => installed_classes_by_id.sort.uniq,
      'installed_devices_by_id' => installed_devices_by_id.sort.uniq,
      'installed_devices_by_class_id' => installed_devices_by_class_id,
      'installed_vendors_by_id' => installed_vendors_by_id.sort.uniq,
      'installed_vendors_by_class_id' => installed_vendors_by_class_id,
    }
  end
end
