# @summary Download and extract the distribution archive
#
# @param id
#   An optional identifier that can be used to prevent the archive job from
#   being executed multiple times by remembering its state. This is most useful
#   to distinguish between an initial install and an update.
#
define nextcloud::install::distribution (
  Optional[String] $id = undef,
){
  include 'archive'

  # NOTE: Extra safekeeping is required to prevent duplicate declaration errors.

  # Ensure that the ID does not contain special characters.
  if ($id) {
    $_id = regsubst($id, '[^a-zA-Z0-9_\-]', '', 'G')
  } else {
    $_id = undef
  }

  # Check if this job was already completed by looking up the ID in facter.
  # This should ensure that a job is only run once if $id was specified.
  if (($_id == undef) or
    ($_id and (!('nextcloud_dist_jobs' in $facts) or !($_id in $facts['nextcloud_dist_jobs'])))) {

    # Create the installation directory for the configured version.
    # This will always be created, even if the archive job is skipped, but it
    # will not do any harm.
    if !defined(File[$nextcloud::install_dir]) {
      file { "Create install dir: ${title}":
        ensure => directory,
        path   => $nextcloud::install_dir,
        owner  => $nextcloud::system_user,
        group  => $nextcloud::system_group,
      }
    }

    # Enable special handling if an ID was specified.
    if ($id) {
      # Create a marker file to prevent the archive job from running again.
      # This is most useful to distinguish between an initial install and an
      # update.
      $id_done = "${nextcloud::datadir}/.puppet_dist_${_id}.done"
      exec { "Create ID marker: ${title}":
        command     => "touch ${id_done}",
        path        => $nextcloud::path,
        user        => $nextcloud::system_user,
        logoutput   => $nextcloud::debug,
        refreshonly => true,
        subscribe   => Archive["Extract archive: ${title}"],
      }

      # Tell the archive job to do nothing if the file already exists.
      $archive_creates = $id_done
    } else {
      # Normal behaviour: the archive job will run if the files from the
      # archive cannot be found.
      $archive_creates = $nextcloud::distribution_dir
    }

    # Download and extract the distribution archive.
    $archive_file = "${nextcloud::installroot}/${nextcloud::archive_name}"
    if !defined(Archive[$archive_file]) {
      archive { "Extract archive: ${title}":
        path         => $archive_file,
        source       => "${nextcloud::mirror}/${nextcloud::archive_name}",
        extract      => true,
        extract_path => $nextcloud::install_dir,
        creates      => $archive_creates,
        user         => $nextcloud::system_user,
        group        => $nextcloud::system_group,
        cleanup      => true,
        require      => File[$nextcloud::install_dir],
      }
    }

    if ($nextcloud::manage_symlink) {
      if !defined(File[$nextcloud::symlink]) {
        # Switch the symlink to the new version.
        file { "Manage docroot symlink: ${title}":
          ensure  => link,
          path    => $nextcloud::symlink,
          target  => $nextcloud::distribution_dir,
          require => Archive["${nextcloud::installroot}/${nextcloud::archive_name}"]
        }
        # Maintain a symlink to the current config file.
        -> file { "Manage config symlink: ${title}":
          ensure  => link,
          path    => $nextcloud::config_symlink,
          target  => $nextcloud::config_file,
          require => Archive["${nextcloud::installroot}/${nextcloud::archive_name}"]
        }
      }
    }

    # Record Nextcloud's home directory, so that it can be used by the custom fact.
    if !defined(File[$nextcloud::statefile]) {
      file { "Create statefile: ${title}":
        ensure  => file,
        path    => $nextcloud::statefile,
        content => inline_epp('<%= $nextcloud::symlink %>'),
        owner   => $nextcloud::system_user,
        group   => $nextcloud::system_group,
        require => Archive["${nextcloud::installroot}/${nextcloud::archive_name}"]
      }
    }
  }
}
