# @summary Configure Nextcloud's High Performance Back-end (HPB)
# @api private
class nextcloud::hpb {
  assert_private()

  # Proceed only if this feature is enabled.
  if ($nextcloud::manage_hpb) {
    # Check if the required app is already installed (or needs to be reinstalled
    # after performing an update of Nextcloud).
    if (!(('enabled' in $facts['nextcloud_apps']) and ($nextcloud::hpb_app in $facts['nextcloud_apps']['enabled']))
    and !(('disabled' in $facts['nextcloud_apps']) and ($nextcloud::hpb_app in $facts['nextcloud_apps']['disabled'])))
    or !($nextcloud::version_normalized in $facts['nextcloud_updates']) {
      # App needs to be installed.
      nextcloud::app_command { "install ${nextcloud::hpb_app}":
        app     => $nextcloud::hpb_app,
        command => 'install',
        before  => [
          File[$nextcloud::hpb_service_config_file],
          File[$nextcloud::hpb_service_file]
        ],
      }
    }

    $hpb_config = {
      config         => $nextcloud::config_symlink,
      binary         => "${nextcloud::distribution_dir}/${nextcloud::hpb_binary}",
      path           => $nextcloud::distribution_dir,
      pidfile        => $nextcloud::hpb_pidfile,
      port           => $nextcloud::hpb_port,
      provider       => $nextcloud::service_provider,
      service_config => $nextcloud::hpb_service_config_file,
      user           => $nextcloud::system_user,
    }

    # Create service configuration file
    file { $nextcloud::hpb_service_config_file:
      ensure  => 'file',
      mode    => '0640',
      content => epp("${module_name}/hpb.service.config",$hpb_config),
    }

    # Install service script
    file { $nextcloud::hpb_service_file:
      ensure  => 'file',
      mode    => $nextcloud::hpb_service_mode,
      content => epp("${module_name}/hpb.service.${nextcloud::service_provider}",$hpb_config),
    }

    # Enable and start service
    service { $nextcloud::hpb_service_name:
      ensure    => $nextcloud::hpb_service_ensure,
      enable    => true,
      subscribe => [
        File[$nextcloud::hpb_service_config_file],
        File[$nextcloud::hpb_service_file]
      ],
    }
  }
}
