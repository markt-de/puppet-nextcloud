# @summary Set or remove a single configuration value
#
# @param key
#   The configuration key that should be altered. If prefixed with `DELETE:`
#   then the key will be completely removed from configuration.
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
  Variant[Boolean, Integer, String] $value,
  Variant[Boolean, Integer, String] $verify_key,
  Variant[Boolean, Integer, String] $verify_value,
  Variant[Boolean, Integer, String] $key = $title,
){
  # Check if the configuration key should be removed.
  $_key = split($key, /:/)
  case $_key[0] {
    'DELETE': {
      $cfg_key = $_key[1]
      $_occ_cmd = 'config:system:delete'
      $_occ_args = $cfg_key
      $unless_cmd = join([
        "php occ config:system:get ${cfg_key}",
        # Modify the exit code to work with Exec's "unless".
        '; _exit=$?; test $_exit -gt 0'
      ], ' ')
    }
    default: {
      $cfg_key = $key
      $_occ_cmd = 'config:system:set'
      $_occ_args = "${cfg_key} --value=\'${value}\'"
      $unless_cmd = join([
        'php occ config:system:get',
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
