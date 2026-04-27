# frozen_string_literal: true

# @summary Returns PCI device information from `lspci`.
#
# This fact returns a deterministic, machine-readable view of the system's PCI
# topology, enabling downstream Puppet modules to make hardware-specific
# decisions or generate inventory reports. It gracefully falls back when `lspci`
# is unavailable or a device lacks a complete identifier set.
#
# The fact runs `lspci -vmm` (human‑readable) and `lspci -vmmn` (hex codes)
# and builds a multi‑part hash:
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

      key = key.strip
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

  # Normalize hex value: strip, validate non-empty, lowercase, prepend 0x
  # Returns nil if value is nil or empty after strip
  def normalize_hex(value)
    return nil if value.nil?
    value = value.strip
    return nil if value.empty?
    '0x' + value.downcase
  end

  # Extract field with vmm->vmmn fallback and optional hex normalization
  # For hex fields: always render as hex if present
  # For text fields: use raw value
  # Returns nil if field not in either source or empty after strip
  def get_field(vmm, vmmn, field, hex: false)
    value = vmm[field] || vmmn[field]
    return nil if value.nil?
    value = value.strip
    return nil if value.empty?
    hex ? '0x' + value.downcase : value
  end

  # Finalize a flat Hash[String => Array] by sorting and deduplicating each array
  # Returns a new hash; does not modify the original
  def dedupe_and_sort_arrays(hash)
    hash.transform_values { |value| value.sort.uniq }
  end

  setcode do
    # return {} if we can't look for facts
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

      # Extract and validate required hex IDs from vmmn (spec-compliant devices must have these)
      # vmmn is the source of truth for hex IDs; skip slot if missing any required field
      class_hex = normalize_hex(vmmn['Class'])
      vendor_hex = normalize_hex(vmmn['Vendor'])
      device_hex = normalize_hex(vmmn['Device'])

      # Skip non-spec-compliant devices: must have all three required hex IDs
      next unless class_hex && vendor_hex && device_hex

      # Extract human-readable names: vmm is primary source (descriptive strings)
      # Fallback to vmmn hex strings with 0x prefix if vmm missing
      class_human = vmm['Class'] || class_hex
      vendor_human = vmm['Vendor'] || vendor_hex
      device_human = vmm['Device'] || device_hex

      # Extract optional hex IDs and normalize
      svendor_hex = normalize_hex(vmmn['SVendor'])
      sdevice_hex = normalize_hex(vmmn['SDevice'])

      # Build by_name properties object
      by_name_props = {}

      # Add human-readable fields
      by_name_props['Class'] = class_human
      by_name_props['Device'] = device_human
      by_name_props['Vendor'] = vendor_human

      # Add optional human-readable SVendor/SDevice
      svendor_name = vmm['SVendor'] || svendor_hex
      by_name_props['SVendor'] = svendor_name if svendor_name

      sdevice_name = vmm['SDevice'] || sdevice_hex
      by_name_props['SDevice'] = sdevice_name if sdevice_name

      # Add hex ID fields (required)
      by_name_props['ClassID'] = class_hex
      by_name_props['DeviceID'] = device_hex
      by_name_props['VendorID'] = vendor_hex

      # Add optional hex ID fields
      by_name_props['SVendorID'] = svendor_hex if svendor_hex
      by_name_props['SDeviceID'] = sdevice_hex if sdevice_hex

      # Add optional hex fields (ProgIf, Rev) - always rendered as hex if present
      progif_hex = get_field(vmm, vmmn, 'ProgIf', hex: true)
      by_name_props['ProgIf'] = progif_hex if progif_hex

      rev_hex = get_field(vmm, vmmn, 'Rev', hex: true)
      by_name_props['Rev'] = rev_hex if rev_hex

      # Add optional text fields (Driver, PhySlot)
      driver = vmm['Driver'] || vmmn['Driver']
      by_name_props['Driver'] = driver if driver

      physlot = vmm['PhySlot'] || vmmn['PhySlot']
      by_name_props['PhySlot'] = physlot if physlot

      # Handle Module specially - always array if present
      module_value = vmm['Module'] || vmmn['Module']
      if module_value
        by_name_props['Module'] = Array(module_value).map(&:to_s).sort.uniq
      end

      # Populate by_name tree
      by_name[class_human] ||= {}
      by_name[class_human][vendor_human] ||= {}
      by_name[class_human][vendor_human][slot] = by_name_props

      # Populate ID lists (safe because we already validated class_hex, vendor_hex, device_hex above)
      installed_classes_by_id << class_hex
      installed_vendors_by_id << vendor_hex
      installed_devices_by_id << "#{vendor_hex}.#{device_hex}"

      installed_devices_by_class_id[class_hex] ||= []
      installed_devices_by_class_id[class_hex] << "#{vendor_hex}.#{device_hex}"

      installed_vendors_by_class_id[class_hex] ||= []
      installed_vendors_by_class_id[class_hex] << vendor_hex

      by_id[vendor_hex] ||= {}
      by_id[vendor_hex][device_hex] ||= []
      by_id[vendor_hex][device_hex] << slot
      by_id[vendor_hex][device_hex] = by_id[vendor_hex][device_hex].sort.uniq
    end

    # Return {} if no devices found (graceful degradation)
    return {} if by_name.empty?

    {
      'by_id'   => sort_hash_deep(by_id),
      'by_name' => sort_hash_deep(by_name),
      'installed_classes_by_id' => installed_classes_by_id.sort.uniq,
      'installed_devices_by_id' => installed_devices_by_id.sort.uniq,
      'installed_devices_by_class_id' => dedupe_and_sort_arrays(installed_devices_by_class_id),
      'installed_vendors_by_id' => installed_vendors_by_id.sort.uniq,
      'installed_vendors_by_class_id' => dedupe_and_sort_arrays(installed_vendors_by_class_id),
    }
  end
end
