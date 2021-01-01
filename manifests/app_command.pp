# @summary Run a command for a Nextcloud app
#
# @param app 
#   The name of the app.
#
# @param command
#   The app command that should be executed.
#
define nextcloud::app_command (
  Enum['install','remove','enable','disable','install_disable'] $command,
  String $app = $title,
){
  case $command {
    'install_disable': {
      $real_command = 'install --keep-disabled'
    }
    default: {
      $real_command = $command
    }
  }

  # Commands and files required when performing an update.
  $app_lock = "${nextcloud::datadir}/.puppet_app.lock"
  $app_cmd = join([
    "touch ${app_lock}",
    "&& php occ app:${real_command} ${app}",
    '; _exit=$?', # record exit code
    "; rm -f ${app_lock}", # always remove lock
    '; test $_exit -lt 1 && true', # pass failures to puppet
  ], ' ')

  # Run the app command.
  # NOTE: The command will not run if an update of Nextcloud is running.
  exec { "occ app:${command} ${app}":
    command   => $app_cmd,
    path      => $nextcloud::path,
    cwd       => $nextcloud::distribution_dir,
    onlyif    => "test ! -f ${app_lock} -a ! -f ${nextcloud::update::update_lock}",
    user      => $nextcloud::system_user,
    logoutput => $nextcloud::debug,
  }
}
