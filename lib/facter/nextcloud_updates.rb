Facter.add('nextcloud_updates') do
  confine kernel: ['FreeBSD', 'Linux']

  # Store all completed update versions here.
  versions = []

  # Try to get Nextcloud's data directory path.
  nextcloud_datastatefile = '/var/db/nextcloud_data'
  if File.exist?(nextcloud_datastatefile)
    # Read only the first line.
    nextcloud_data = File.open(nextcloud_datastatefile, &:readline)
    nextcloud_data = nextcloud_data.chomp

    # Ensure that the data directory exists.
    if File.exist?(nextcloud_data)

      # Get filenames for all completed updates.
      updates = Dir[nextcloud_data + '/.puppet_update_*.done'].map { |a| File.basename(a, '.done') }

      # Iterate over all filenames.
      updates.each do |update|
        # Extract the version information.
        version = update.match(%r{^.puppet_update_(.*)$})
        versions += [version[1]]
      end
    end
  end

  # Add update versions to fact.
  setcode do
    versions
  end
end
