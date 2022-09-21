# @summary Configure background cron jobs for Nextcloud
# @api private
class nextcloud::cron {
  assert_private()

  # Only manage cron jobs if this feature is enabled.
  if ($nextcloud::manage_cron) {
    # Iterate over all cron jobs.
    $nextcloud::cronjobs.each | $_cron, $_config| {
      # Ignore invalid cron configurations.
      if (($_config =~ Hash) and ('command' in $_config)) {
        # Set environment variables.
        if ('environment' in $_config) {
          $_environment = $_config['environment'] + ["PATH=${nextcloud::path}"]
        } else {
          $_environment = ["PATH=${nextcloud::path}"]
        }
        # Add Nextcloud's installation directory to the command.
        $_cmd = sprintf($_config['command'], $nextcloud::symlink)

        # Ensure that the cron job does not run during updates.
        $_real_cmd = "test ! -f ${nextcloud::update::update_lock} && ${_cmd}"

        # Finalize the config by adding Nextcloud's username.
        $_real_config = $_config + {
          command     => $_real_cmd,
          environment => $_environment,
          user        => $nextcloud::system_user,
        }

        # Finally add the cron job.
        cron { $_cron:
          * => $_real_config,
        }
      } else {
        fail("Invalid config for cron job \'${_cron}\'")
      }
    }
  }
}
