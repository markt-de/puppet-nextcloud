# @summary Create nextcloud::config_command resources from a nested hash (e.g. from hiera)
#
# Create nextcloud::config_command resources from a nested hash, suitable for
# conveniently loading values from hiera.
# The key-value pairs from the hash represent config keys and values
# passed to nextcloud::config_command for simple values, Hash and Array values
# recursively # create nested sections.
#
# @param config_hash
#   A hash of (non-hierarchical) key names mapped to values.
#
# @param sections
#   The section names of the hierarchical key, will usually only be specified
#   on recursive calls from within this function itself.
#
# @see nextcloud::config_command
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
# @author Frank Wall <fw@moov.de>
#
function nextcloud::create_config_resources(Hash[String, NotUndef] $config_hash, Array[String] $sections=[]) {
  $config_hash.each |$key, $value| {
    case $value {
      Hash: {
        nextcloud::create_config_resources($value, $sections + $key)
      }
      Array: {
        $value.each |$idx,$val| {
          nextcloud::create_config_resources( { "${idx}" => $val }, $sections + $key)
        }
      }
      default: {
        $_key = "${join($sections + $key, ' ')}"
        nextcloud::config_command { $_key:
          section      => 'system',
          value        => $value,
          verify_key   => $_key,
          verify_value => $value,
        }
      }
    }
  }
}
