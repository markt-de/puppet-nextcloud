require 'spec_helper'

describe 'nextcloud' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        let(:params) do
          {
            admin_password: 'secret',
            db_password: 'secret',
            version: '20.0.4',
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('nextcloud::pre_install') }
        it { is_expected.to contain_class('nextcloud::install') }
        it { is_expected.to contain_class('nextcloud::update') }
        it { is_expected.to contain_class('nextcloud::apps') }
        it { is_expected.to contain_class('nextcloud::config') }
        it { is_expected.to contain_class('nextcloud::app_config') }
        it { is_expected.to contain_class('nextcloud::cron') }

        it { is_expected.to contain_file('/opt/nextcloud-data').with_ensure('directory') }
        it { is_expected.to contain_file('Create install dir: initial install').with_ensure('directory') }

        it {
          is_expected.to contain_cron('Nextcloud background job').with(
            command: 'test ! -f /opt/nextcloud-data/.puppet_update.lock && php -f /opt/nextcloud/cron.php',
            environment: ['PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin'],
            minute: '*/5',
          )
        }
      end
    end
  end
end
