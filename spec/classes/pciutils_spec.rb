# frozen_string_literal: true

require 'spec_helper'

describe 'pciutils' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe 'with defaults' do
        it { is_expected.to compile }
        it { is_expected.to contain_package('pciutils').with_ensure('installed') }
        it { is_expected.to have_package_resource_count(1) }
      end

      describe 'with params' do
        let(:params) do
          {
            'package_names' => ['a', 'b'],
            'package_ensure' => 'absent',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_package('a').with_ensure('absent') }
        it { is_expected.to contain_package('b').with_ensure('absent') }
        it { is_expected.to have_package_resource_count(2) }
      end
    end
  end
end
