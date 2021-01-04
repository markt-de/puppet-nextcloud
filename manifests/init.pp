# @summary Install and manage Nextcloud
#
# @param admin_password
#   Specifies the initial password for the Nextcloud admin user.
#
# @param admin_user
#   Specifies the username for the Nextcloud admin.
#
# @param apps
#   Specifies a list of Nextcloud apps and their desired state.
#
# @param command_timeout
#   Specifies the time to wait for install/update/maintenance commands
#   to complete. Keep in mind that several commands may take a few hours
#   to complete, depending on the size of your installation.
#
# @param config
#   A hash containing configuration options for Nextcloud.
#
# @param cronjobs
#   Specifies a list of cron jobs that should be added when
#   `$manage_cron` is enabled.
#
# @param datadir
#   Specifies the directory where Nextcloud will store user data.
#   It MUST reside outside of Nextcloud's installation directory.
#
# @param datastatefile
#   A file that is required by the module to work properly. This value MUST NOT
#   be changed, because the path is hardcoded in several places.
#
# @param debug
#   Whether to enable additional output for debugging purposes.
#
# @param install_enabled
#   Whether to download and extract the release distribution files, switch the
#   symlink to the specified release. On new installs it also runs the required
#   PHP commands to install Nextcloud. When disabled these commands need to be
#   run manually and some features may not work as expected (not recommended).
#
# @param installroot
#   Specifies the base directory where Nextcloud should be installed. A new
#   subdirectory for each version will be created.
#
# @param manage_apps
#   Whether to manage Nextcloud apps. They can be installed, removed, enabled
#   or disabled.
#
# @param manage_cron
#   Whether to manage Nextcloud's background cron job(s).
#
# @param manage_php
#   Whether to setup and maintain PHP (FPM/CLI) and install modules needed
#   for Nextcloud.
#
# @param manage_redis
#   Whether to setup and maintain a local Redis server.
#
# @param manage_symlink
#   Whether to maintain a symlink for the current version of Nextcloud.
#   This must be enabled for the module to work as expected.
#
# @param mirror
#   Specifies the base URL where the distribution archive can be downloaded.
#
# @param path
#   Specifies the content of the PATH environment variable when running commands.
#
# @param php_extensions
#   Specifies a list of PHP extensions that should be installed when
#   `$manage_php` is enabled.
#
# @param statefile
#   A file that is required by the module to work properly. This value MUST NOT
#   be changed, because the path is hardcoded in several places.
#
# @param symlink_name
#   Specifies the name of the symlink. This is considered to represent
#   Nextcloud's home directory. It should be used as DocumentRoot and MUST NOT
#   be changed after completing the Nextcloud installation.
#
# @param system_group
#   Specifies the name of the group that is used by the webserver and/or PHP FPM.
#   It will be used to set proper file permission for Nextcloud.
#
# @param system_user
#   Specifies the name of the user that is used by the webserver and/or PHP FPM.
#   It will be used as owner for the Nextcloud installation files and it will be
#   used to run optional commands.
#
# @param update_enabled
#   Whether to run the required PHP commands to update Nextcloud. When disabled,
#   these commands need to be run manually and some features may not work as
#   expected. Note that this does NOT prevent the module from switching the
#   installation directory to a newer version, it just skips the execution of
#   Nextcloud's update commands. To completely disable all updates, the parameter
#   should be set to `none` (not recommended).
#
# @param version
#   Specifies the version of Nextcloud that should be installed.
#
class nextcloud (
  Hash $apps,
  String $admin_password,
  String $admin_user,
  Integer $command_timeout,
  Hash $config,
  Hash $cronjobs,
  Stdlib::Compat::Absolute_path $datadir,
  Stdlib::Compat::Absolute_path $datastatefile,
  String $db_driver,
  String $db_host,
  String $db_name,
  String $db_password,
  String $db_user,
  Boolean $debug,
  Boolean $install_enabled,
  Stdlib::Compat::Absolute_path $installroot,
  Boolean $manage_apps,
  Boolean $manage_cron,
  Boolean $manage_php,
  Boolean $manage_redis,
  Boolean $manage_symlink,
  Variant[Stdlib::HTTPUrl,Stdlib::HTTPSUrl] $mirror,
  String $path,
  Hash $php_extensions,
  Stdlib::Compat::Absolute_path $statefile,
  String $symlink_name,
  String $system_group,
  String $system_user,
  Variant[Boolean, Enum['none']] $update_enabled,
  String $version,
) {
  # Merge configuration options.
  $default_config = {
    dbhost => $db_host,
    dbname => $db_name,
    dbpassword => $db_password,
    dbuser => $db_user,
    datadirectory => $datadir,
  }
  $real_config = $default_config + $config

  # Set the archive filename.
  $archive_name = "${module_name}-${nextcloud::version}.tar.bz2"

  # Set version-specific target directory where the archive will be extracted to.
  $install_dir = "${nextcloud::installroot}/${module_name}-${nextcloud::version}"

  # Set directory that contains the extracted runtime files.
  $distribution_dir = "${install_dir}/${module_name}"

  # Set symlink that points to the current Nextcloud installation.
  $symlink = "${nextcloud::installroot}/${nextcloud::symlink_name}"

  # Set config file location.
  $config_file = "${datadir}/.config.php"
  $config_symlink = "${symlink}/config/config.php"

  # Normalized version, used for some filenames.
  $version_normalized = regsubst($nextcloud::version, '[^0-9]', '_', 'G')

  # NOTE: All commands should use a simple lock mechanism to prevent concurrent
  # execution when multiple servers are used:
  # 
  # - create a lock file as part of the command execution
  # - do not run the Exec if the lock file can be found
  # - remove the lock file as part of the command execution
  # 
  # The lock file should be created in Nextcloud's data directory, because
  # this is most likely shared between all servers.
  # 
  # Ensure that the lock file is removed, even if the command fails. This way
  # a failed command can be retried.

  class { 'nextcloud::pre_install': }
  -> class { 'nextcloud::install': }
  -> class { 'nextcloud::update': }
  -> class { 'nextcloud::apps': }
  -> class { 'nextcloud::config': }
  -> class { 'nextcloud::cron': }
}
