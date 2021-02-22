# @summary Set configuration options for Nextcloud
# @api private
class nextcloud::config {
  assert_private()
  # Use a custom function to generate nextcloud::config_command resources.
  nextcloud::create_config_resources($nextcloud::real_config)
}
