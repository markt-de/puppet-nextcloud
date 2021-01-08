# @summary Manage Nextcloud apps
# @api private
class nextcloud::apps {
  assert_private()

  if ($nextcloud::manage_apps and !empty($nextcloud::apps)) {

    # For safekeeping, do not try to manage apps when the fact is empty.
    if (('nextcloud_apps' in $facts) and !empty($facts['nextcloud_apps'])) {

      # Walk through the list of apps.
      $nextcloud::apps.each | $_name, $_config| {

        # Get desired app state from config or fallback to default value.
        $_ensure = ($_config =~ Hash and 'ensure' in $_config and
          $_config['ensure'] =~ Enum['present','absent']) ? {
          false   => 'present',
          default => $_config['ensure'],
        }
        $_status = ($_config =~ Hash and 'status' in $_config and
          $_config['status'] =~ Enum['enabled','disabled']) ? {
          false   => 'enabled',
          default => $_config['status'],
        }

        # Install the app if the following conditions are met:
        # - it is neither listed as "enabled" nor "disabled" apps
        # - an update is in progress (the Nextcloud version is not listed as completed update)
        if ($_ensure == 'present'
          and (
          (!(('enabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['enabled']))
          and !(('disabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['disabled']))
          ) or !($nextcloud::version_normalized in $facts['nextcloud_updates'])
          )) {

          # Check if the app should remain disabled after installation.
          $_cmd = ($_status == 'enabled') ? {
            false   => 'install_disable',
            default => 'install',
          }

          # App needs to be installed.
          nextcloud::app_command { "install ${_name}":
            app     => $_name,
            command => $_cmd,
          }

        # Remove the app if the following conditions are met:
        # - it is listed in "enabled" or "disabled" apps
        } elsif ($_ensure == 'absent'
          and ((('enabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['enabled']))
          or (('disabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['disabled'])))) {

          # App needs to be removed.
          nextcloud::app_command { "remove ${_name}":
            app     => $_name,
            command => 'remove',
          }
        }

        # Enable or disable the app.
        # Compare the desired state to what facter has found on the system.
        # Ignore apps that are either not installed or should be removed.
        if ($_ensure == 'present' and $_status == 'enabled'
          and !(('enabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['enabled']))
          and (('disabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['disabled']))) {

          # App needs to be enabled.
          nextcloud::app_command { "enable ${_name}":
            app     => $_name,
            command => 'enable',
          }

        } elsif ($_ensure == 'present' and $_status == 'disabled'
          and !(('disabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['disabled']))
          and (('enabled' in $facts['nextcloud_apps']) and ($_name in $facts['nextcloud_apps']['enabled']))) {

          # App needs to be disabled.
          nextcloud::app_command { "disable ${_name}":
            app     => $_name,
            command => 'disable',
          }
        }
      }
    } else {
      warning('No Nextcloud apps have been found; app management is disabled for safekeeping. This warning can be ignored on first occurence.') # lint:ignore:140chars
    }
  }
}
