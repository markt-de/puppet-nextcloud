# @summary Run a command for a Nextcloud app
#
# @param app 
#   The name of the app.
#
# @param command
#   The app command that should be executed.
#
define nextcloud::app_command (
  Enum['install','remove','enable','disable','install_disable','post_update'] $command,
  String $app = $title,
){
  # Handle special app commands.
  case $command {
    # Install an app but keep it disabled.
    'install_disable': {
      $real_command = 'install --keep-disabled'
      $pre_command = ''
    }
    # Ensure that an app is installed after updating Nextcloud.
    'post_update': {
      $real_command = 'install'
      # First try to update the app. If this command returns a non-zero
      # exit code, then try to install the app.
      $pre_command = "php occ app:update ${app} ||"
    }
    default: {
      $real_command = $command
      $pre_command = ''
    }
  }

  # Commands and files required for app installation/removal.
  $app_lock = "${nextcloud::datadir}/.puppet_app.lock"
  $app_cmd = join([
    "touch ${app_lock};",
    $pre_command,
    "php occ app:${real_command} ${app}",
    '; _exit=$?', # record exit code
    "; rm -f ${app_lock}", # always remove lock
    '; test $_exit -lt 1 && true', # pass failures to puppet
  ], ' ')

  # Run the app command.
  # NOTE: The command will not run if an update of Nextcloud is running.
  exec { "occ app:${command} ${app}":
    command   => $app_cmd,
    path      => $nextcloud::path,
    cwd       => $nextcloud::symlink,
    onlyif    => "test ! -f ${app_lock} -a ! -f ${nextcloud::update::update_lock}",
    user      => $nextcloud::system_user,
    logoutput => $nextcloud::debug,
  }
}
