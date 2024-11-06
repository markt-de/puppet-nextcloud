# @summary Set or remove a single configuration value
#
# @param key
#   The configuration key that should be altered. If prefixed with `DELETE:`
#   then the key will be completely removed from configuration.
#
# @param section
#   Specifies whether it is a system or app configuration value.
#
# @param value
#   The configuration value that should be set.
#
# @param verify_key
#   The configuration key to find out whether it needs to be altered.
#
# @param verify_value
#   The configuration verify to find out whether it needs to be altered.
#
define nextcloud::config_command (
  Variant[Boolean, Float, Integer, String] $value,
  Variant[Boolean, Integer, String] $verify_key,
  Variant[Boolean, Float, Integer, String] $verify_value,
  Variant[Boolean, Integer, String] $key = $title,
  Enum['app', 'system']             $section = 'system',
) {
  # Check if this is the designated update/install host.
  if (($nextcloud::update_host == undef or empty($nextcloud::update_host))
  or ($nextcloud::update_host == $facts['networking']['fqdn'])) {
    # Check if the configuration key should be removed.
    $_key = split($key, /:/)
    case $_key[0] {
      'DELETE': {
        $cfg_key = $_key[1]
        $_occ_cmd = "config:${section}:delete"
        $_occ_args = $cfg_key
        $unless_cmd = join([
            "php occ config:${section}:get ${cfg_key}",
            # Modify the exit code to work with Exec's "unless".
            '; _exit=$?; test $_exit -gt 0',
        ], ' ')
      }
      default: {
        $cfg_key = $key
        $_occ_cmd = "config:${section}:set"
        if ($value =~ Boolean) {
          $_occ_args = "${cfg_key} --value=${value} --type=boolean"
        } elsif ($value =~ Integer) {
          $_occ_args = "${cfg_key} --value=${value} --type=integer"
        } elsif ($value =~ Float) {
          $_occ_args = "${cfg_key} --value=${value} --type=float"
        } else {
          # Everything else is a string.
          $_occ_args = "${cfg_key} --value=\'${value}\'"
        }
        $unless_cmd = join([
            "php occ config:${section}:get",
            $verify_key,
            '| grep -qF',
            "\'${verify_value}\'",
        ], ' ')
      }
    }

    # Commands and files required to update the configuration.
    $config_lock = "${nextcloud::datadir}/.puppet_config.lock"
    $config_cmd = join([
        "touch ${config_lock}",
        "&& php occ ${_occ_cmd} ${_occ_args}",
        '; _exit=$?', # record exit code
        "; rm -f ${config_lock}", # always remove lock
        '; test $_exit -lt 1 && true', # pass failures to puppet
    ], ' ')

    # Run the config command.
    exec { "occ ${_occ_cmd} ${cfg_key}":
      command   => $config_cmd,
      path      => $nextcloud::path,
      cwd       => $nextcloud::distribution_dir,
      unless    => $unless_cmd,
      user      => $nextcloud::system_user,
      logoutput => $nextcloud::debug,
    }
  }
}
