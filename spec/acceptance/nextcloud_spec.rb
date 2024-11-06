require 'spec_helper_acceptance'

describe 'nextcloud class' do
  context 'default parameters' do
    it 'is expected to work idempotently with no errors' do
      pp = <<-EOS
      if $facts['os']['family'] == 'Debian' {
        $group_name = 'nogroup'
      }
      else {
        $group_name = 'nobody'
      }

      package { 'bzip2':
        ensure => 'present',
      }

      class { 'nextcloud':
        admin_password => 'suPeRseCreT',
        db_password    => 'secRetPasSwOrd',
        # Test containers usually don't have cron installed.
        manage_cron    => false,
        system_group   => $group_name,
        system_user    => 'nobody',
        # The post-update command would break the idempotency test.
        update_enabled => 'none',
        version        => '30.0.1',
      }
      EOS

      apply_manifest(pp, catch_failures: true, hiera_config: '/tmp/hiera.yaml', debug: false)

      # Run it twice and test for idempotency
      idempotent_apply(pp, hiera_config: '/tmp/hiera.yaml', debug: false)
    end
  end
end
