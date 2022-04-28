# frozen_string_literal: true

# _Description_
#
# return the content of lspci as a hash
Facter.add(:lspci) do
  # https://puppet.com/docs/puppet/latest/fact_overview.html
  confine kernel: 'Linux'
  retval = {}

  if Facter::Util::Resolution.which('lspci')
    slot = ''
    type = ''
    vendor = ''
    Facter::Util::Resolution.exec('lspci -vv -mm -k -b -D 2>/dev/null').each_line do |line|
      # only parse lines with text
      if %r{.+}.match?(line)
        txt = line.split(%r{:\t})
        if txt[0] == 'Slot'
          slot = txt[1].strip
          type = ''
          vendor = ''
          next
        elsif txt[0] == 'Class'
          type = txt[1].strip
          next
        elsif txt[0] == 'Vendor'
          vendor = txt[1].strip
          next
        end

        if (type != '') && (slot != '') && (vendor != '')
          unless retval.key?(type)
            retval[type] = {}
          end

          unless retval[type].key?(vendor)
            retval[type][vendor] = {}
          end

          unless retval[type][vendor].key?(slot)
            retval[type][vendor][slot] = {}
          end

          retval[type][vendor][slot][txt[0]] = txt[1].strip
        end
      else
        slot = ''
        type = ''
        vendor = ''
      end
    end
  end

  setcode do
    retval
  end
end
