# @summary Perform required tasks to update Nextcloud
# @api private
class nextcloud::update {
  assert_private()

  # Only perform update tasks if this feature is enabled.
  if ($nextcloud::update_enabled =~ Boolean) {

    # Get and prepare the distribution files
    nextcloud::install::distribution { "update to ${nextcloud::version}": }

    # Only run occ commands if allowed to do so.
    if ($nextcloud::update_enabled == true) {
      # Commands and files required when performing an update.
      $update_lock = "${nextcloud::datadir}/.puppet_update.lock"
      $update_done = "${nextcloud::datadir}/.puppet_update_${nextcloud::version_normalized}.done"
      $update_cmd = join([
        "touch ${update_lock}",
        '&& php occ upgrade --no-interaction',
        "&& touch ${update_done}",
        "; rm -f ${update_lock}", # always remove lock
      ], ' ')

      # Run the update command.
      exec { 'occ upgrade':
        command   => $update_cmd,
        path      => $nextcloud::path,
        cwd       => $nextcloud::distribution_dir,
        creates   => $update_done,
        onlyif    => "test ! -f ${update_lock}",
        user      => $nextcloud::system_user,
        logoutput => $nextcloud::debug,
        require   => Nextcloud::Install::Distribution["update to ${nextcloud::version}"],
      }
    }
  }
}
