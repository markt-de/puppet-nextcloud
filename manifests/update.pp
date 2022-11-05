# @summary Perform required tasks to update Nextcloud
# @api private
class nextcloud::update {
  assert_private()

  # Only perform update tasks if this feature is enabled.
  if ($nextcloud::update_enabled =~ Boolean) {
    # Check if this is the designated update/install host.
    if (($nextcloud::update_host == undef or empty($nextcloud::update_host))
    or ($nextcloud::update_host == $facts['networking']['fqdn'])) {
      # Get and prepare the distribution files
      nextcloud::install::distribution { "update to ${nextcloud::version}":
        before => Exec['post-update command'],
      }

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

    # Only run post-update command if update was less than 30 minutes ago.
    $post_update_onlyif = join([
        "test -f \'${update_done}\'",
        '&&',
        'test',
        "\$( ${nextcloud::stat_expression} \'${update_done}\' )",
        '-gt',
        "\$( ${nextcloud::date_expression} )",
    ], ' ')

    # Run the post-update command.
    exec { 'post-update command':
      command   => $nextcloud::post_update_cmd,
      path      => $nextcloud::path,
      cwd       => $nextcloud::distribution_dir,
      onlyif    => $post_update_onlyif,
      logoutput => $nextcloud::debug,
    }
  }
}
