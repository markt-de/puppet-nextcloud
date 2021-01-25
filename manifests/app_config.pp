# @summary Set configuration options for Nextcloud apps
# @api private
class nextcloud::app_config {
  assert_private()

  $nextcloud::app_config.each | $_app_name, $_app_configs | {
    $_app_configs.each | $_config_key, $_config_value | {
      case $_config_value {
        String, Boolean, Integer: {
          nextcloud::config_command { "${_app_name} ${_config_key}":
            section      => 'app',
            value        => $_config_value,
            verify_key   => "${_app_name} ${_config_key}",
            verify_value => $_config_value,
          }
        }
        Array: {
          $_config_value.each | $_index, $_config_array_value | {
            nextcloud::config_command { "${_app_name} ${_config_key} ${_index}":
              section      => 'app',
              value        => $_config_array_value,
              verify_key   => "${_app_name} ${_config_key}",
              verify_value => $_config_array_value,
            }
          }
        }
        Hash: {
          $_config_value.each | $_config_hash_key, $_config_hash_value | {
            nextcloud::config_command { "${_app_name} ${_config_key} \'${_config_hash_key}\'":
              section      => 'app',
              value        => $_config_hash_value,
              verify_key   => "${_app_name} ${_config_key} ${_config_hash_key}",
              verify_value => $_config_hash_value,
            }
          }
        }
        default: {
          fail("Unexpected data type in config for key ${_config_key}")
        }
      }
    }
  }
}
