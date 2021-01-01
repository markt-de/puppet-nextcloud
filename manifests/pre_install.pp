# @summary Pre installation tasks
# @api private
class nextcloud::pre_install {
  assert_private()

  if $nextcloud::manage_redis {
    include 'redis'
  }

  if $nextcloud::manage_php {
    class { 'php':
      extensions => $nextcloud::php_extensions,
    }
  }
}
