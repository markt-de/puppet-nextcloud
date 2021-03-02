require 'spec_helper_acceptance'

describe 'nextcloud class' do
  group_name = case fact('osfamily')
               when 'Debian'
                 'nogroup'
               else
                 'nobody'
               end

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'is expected to work idempotently with no errors' do
      pp = <<-EOS
      class { 'nextcloud':
        admin_password => 'suPeRseCreT',
        db_password    => 'secRetPasSwOrd',
        system_group   => #{group_name},
        system_user    => 'nobody',
        version        => '21.0.0',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
  end
end
