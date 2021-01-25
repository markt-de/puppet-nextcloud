# @summary Set configuration options for Nextcloud
# @api private
class nextcloud::config {
  assert_private()

  $nextcloud::real_config.each | $_config_key, $_config_value | {
    case $_config_value {
      String, Boolean, Integer: {
        nextcloud::config_command { $_config_key:
          section      => 'system',
          value        => $_config_value,
          verify_key   => $_config_key,
          verify_value => $_config_value,
        }
      }
      Array: {
        $_config_value.each | $_index, $_config_array_value | {
          nextcloud::config_command { "${_config_key} ${_index}":
            section      => 'system',
            value        => $_config_array_value,
            verify_key   => $_config_key,
            verify_value => $_config_array_value,
          }
        }
      }
      Hash: {
        $_config_value.each | $_config_hash_key, $_config_hash_value | {
          nextcloud::config_command { "${_config_key} \'${_config_hash_key}\'":
            section      => 'system',
            value        => $_config_hash_value,
            verify_key   => "${_config_key} ${_config_hash_key}",
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
