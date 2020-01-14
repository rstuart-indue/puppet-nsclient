require 'spec_helper'

describe 'nsclient', type: :class do
  let(:facts) do
    {
      osfamily: 'Windows'
    }
  end
  let(:params) do
    {
      package_source_location: 'https://github.com/mickem/nscp/releases/download/0.5.1.28',
      package_name: 'NSCP-0.5.1.28-x64.msi',
      download_destination: 'c:/temp'
    }
  end

  context 'using params defaults' do
    it { is_expected.to contain_class('nsclient') }
    it { is_expected.to contain_class('nsclient::install').that_comes_before('Class[nsclient::service]') }
    it { is_expected.to contain_class('nsclient::service') }
    it { is_expected.to contain_class('nsclient::params') }
    it do
      is_expected.to contain_download_file('NSCP-Installer').with(
        'url'                   => 'https://github.com/mickem/nscp/releases/download/0.5.1.28/NSCP-0.5.1.28-x64.msi',
        'destination_directory' => 'c:/temp'
      )
    end
    it do
      is_expected.to contain_package('NSCP-0.5.1.28-x64.msi').with(
        'ensure'   => '0.5.1.28',
        'provider' => 'windows',
        'source'   => 'c:/temp/NSCP-0.5.1.28-x64.msi',
        'require'  => 'Download_file[NSCP-Installer]'
      )
    end
    it { is_expected.to contain_service('nscp').with_ensure('running') }
    #
  end

  context 'installing a custom version' do
    let(:params) do
      {
        package_version: 'Custom-build',
        package_source: 'NSCP-Custom-build-x64.msi',
        package_name: 'NSClient++ (x64)',
        package_source_location: 'http://myproxy.com:8080'
      }
    end

    it do
      is_expected.to contain_package('NSClient++ (x64)').with(
        'ensure'   => 'Custom-build',
        'provider' => 'windows',
        'source'   => 'c:/temp/NSCP-Custom-build-x64.msi',
        'require'  => 'Download_file[NSCP-Installer]'
      )
    end
  end

  context 'when trying to install on Ubuntu' do
    let(:facts) { { osfamily: 'Ubuntu' } }

    it do
      expect do
        is_expected.to contain_class('nsclient')
      end.to raise_error(Puppet::Error, %r{This module only works on Windows based systems.})
    end
  end

  context 'with service_state set to stopped' do
    let(:params) { { 'service_state' => 'stopped' } }

    it { is_expected.to contain_service('nscp').with_ensure('stopped') }
  end

  context 'with service_enable set to false' do
    let(:params) { { 'service_enable' => 'false' } }

    it { is_expected.to contain_service('nscp').with_enable('false') }
  end

  context 'with service_enable set to true' do
    let(:params) { { 'service_enable' => 'true' } }

    it { is_expected.to contain_service('nscp').with_enable('true') }
  end

  context 'when single value array of allowed hosts' do
    let(:params) { { 'allowed_hosts' => ['172.16.0.3'], 'service_state' => 'running', 'service_enable' => 'true' } }

    it { is_expected.to contain_file('C:\Program Files\NSClient++\nsclient.ini').with_content(%r{allowed hosts = 172\.16\.0\.3}) }
  end

  context 'when passing an array of allowed hosts' do
    let(:params) { { 'allowed_hosts' => ['10.21.0.0/22', '10.21.4.0/22'], 'service_state' => 'running', 'service_enable' => 'true' } }

    # it { should contain_file('C:\Program Files\NSClient++\nsclient.ini').with_content(/allowed hosts = 10\.21\.0\.0\/22,10\.21\.4\.0\/22/) }
    it { is_expected.to contain_file('C:\Program Files\NSClient++\nsclient.ini').with_content(%r{allowed hosts = 10.21.0.0/22,10.21.4.0/22}) }
  end

  context 'when passing password variable' do
    let(:params) { { 'password' => 'debian4ever', 'service_state' => 'running', 'service_enable' => 'true' } }

    it { is_expected.to contain_file('C:\Program Files\NSClient++\nsclient.ini').with_content(%r{password = debian4ever}) }
  end
end
