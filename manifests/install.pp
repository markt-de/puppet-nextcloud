# @summary Download and extract the distribution archive
# @api private
class nextcloud::install {
  assert_private()

  # Create the data directory.
  file { $nextcloud::datadir:
    ensure => directory,
    owner  => $nextcloud::system_user,
    group  => $nextcloud::system_group,
    before => Nextcloud::Install::Distribution['initial install'],
  }

  # Record Nextcloud's datadirectory, so that it can be used by the custom fact.
  file { 'Create data statefile':
    ensure  => file,
    path    => $nextcloud::datastatefile,
    content => inline_epp('<%= $nextcloud::datadir %>'),
    owner   => $nextcloud::system_user,
    group   => $nextcloud::system_group,
  }

  # Perform initial installation of all required files and directories.
  # This is essential for this module so it cannot be disabled.
  nextcloud::install::distribution { 'initial install':
    id => 'initial_install',
  }

  # Run Nextcloud's installation commands.
  if ($nextcloud::install_enabled) {

    # During initial install, also mark the update to the current version
    # as complete. This prevents the updater from running right afterwards.
    $update_done = "${nextcloud::datadir}/.puppet_update_${nextcloud::version_normalized}.done"

    # Commands and files required for the initial install.
    $install_lock = "${nextcloud::datadir}/.puppet_install.lock"
    $install_done = "${nextcloud::datadir}/.puppet_install.done"
    $install_cmd = join([
      "touch ${install_lock}",
      # Hint: occ commands may fail when using NFS with the "mapall" option.
      "; php occ maintenance:install --database '${nextcloud::db_driver}'",
      "--database-host ${nextcloud::db_host}",
      "--database-name ${nextcloud::db_name}",
      "--database-user ${nextcloud::db_user}",
      "--database-pass \'${nextcloud::db_password}\'",
      "--admin-user ${nextcloud::admin_user}",
      "--admin-pass ${nextcloud::admin_password}",
      "--data-dir ${nextcloud::datadir}",
      "&& touch ${install_done}",
      "&& touch ${update_done}",
      '; _exit=$?', # record exit code
      "; rm -f ${install_lock}", # always remove lock
      '; test $_exit -lt 1 && true', # pass failures to puppet
    ], ' ')

    # Run the installation command.
    exec { 'occ maintenance:install':
      command   => $install_cmd,
      path      => $nextcloud::path,
      cwd       => $nextcloud::distribution_dir,
      creates   => $install_done,
      onlyif    => "test ! -f ${install_lock}",
      user      => $nextcloud::system_user,
      logoutput => $nextcloud::debug,
      require   => Nextcloud::Install::Distribution['initial install'],
    }

    $missing_indices_lock = "${nextcloud::datadir}/.puppet_missing_indices.lock"
    $missing_indices_done = "${nextcloud::datadir}/.puppet_missing_indices.done"
    $missing_indices_cmd = join([
      "touch ${missing_indices_lock}",
      '&& php occ db:add-missing-indices --no-interaction',
      "&& touch ${missing_indices_done}",
      "; rm -f ${missing_indices_lock}", # always remove lock
    ], ' ')

    exec { 'occ db:add-missing-indices':
      command     => $missing_indices_cmd,
      path        => $nextcloud::path,
      cwd         => $nextcloud::distribution_dir,
      creates     => $missing_indices_done,
      onlyif      => "test ! -f ${missing_indices_lock}",
      user        => $nextcloud::system_user,
      refreshonly => true,
      subscribe   => Exec['occ maintenance:install'],
      logoutput   => $nextcloud::debug,
    }

    $convert_filecache_lock = "${nextcloud::datadir}/.puppet_convert_filecache.lock"
    $convert_filecache_done = "${nextcloud::datadir}/.puppet_convert_filecache.done"
    $convert_filecache_cmd = join([
      "touch ${convert_filecache_lock}",
      'php occ db:convert-filecache-bigint --no-interaction',
      "&& touch ${convert_filecache_done}",
      "; rm -f ${convert_filecache_lock}", # always remove lock
    ], ' ')

    exec { 'occ db:convert-filecache-bigint':
      command     => $convert_filecache_cmd,
      path        => $nextcloud::path,
      cwd         => $nextcloud::distribution_dir,
      creates     => $convert_filecache_done,
      onlyif      => "test ! -f ${convert_filecache_lock}",
      user        => $nextcloud::system_user,
      refreshonly => true,
      subscribe   => Exec['occ maintenance:install'],
      logoutput   => $nextcloud::debug,
    }
  }
}
