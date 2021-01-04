require 'json'
Facter.add('nextcloud_apps') do
  confine kernel: ['FreeBSD', 'Linux']
  setcode do
    # The statefile contains the location of the Nextcloud folder.
    nextcloud_statefile = '/var/db/nextcloud_home'
    if File.exist?(nextcloud_statefile)
      # Read only the first line.
      nextcloud_home = File.open(nextcloud_statefile, &:readline)
      nextcloud_home.chomp
      occ = "#{nextcloud_home}/occ"
      # Ensure that the requirements are met before running the occ command.
      if File.exist?(nextcloud_home) && File.exist?(occ) && Facter::Util::Resolution.which('php')
        Dir.chdir(nextcloud_home) do
          # Get owner of the file.
          occ_uid = File.stat(occ).uid
          # Run occ command as the user that owns this file.
          # NOTE: This may fail when using NFS with the "mapall" option.
          JSON.parse(Puppet::Util::Execution.execute('php occ app:list --ansi --output=json', uid: occ_uid))
        end
      else
        nil
      end
    end
  end
end
