Facter.add('nextcloud_dist_jobs') do
  confine kernel: ['FreeBSD', 'Linux']

  # Store all IDs here.
  ids = []

  # Try to get Nextcloud's data directory path.
  nextcloud_datastatefile = '/var/db/nextcloud_data'
  if File.exist?(nextcloud_datastatefile)
    # Read only the first line.
    nextcloud_data = File.open(nextcloud_datastatefile, &:readline)
    nextcloud_data = nextcloud_data.chomp

    # Ensure that the data directory exists.
    if File.exist?(nextcloud_data)

      # Get filenames for all completed dist jobs.
      markers = Dir[nextcloud_data + '/.puppet_dist_*.done'].map { |a| File.basename(a, '.done') }

      # Iterate over all filenames.
      markers.each do |marker|
        # Extract the dist job ID.
        marker_id = marker.match(%r{^.puppet_dist_(.*)$})
        ids += [marker_id[1]]
      end
    end
  end

  # Add IDs to fact.
  setcode do
    ids
  end
end
