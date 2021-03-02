# puppet-nextcloud

[![Build Status](https://travis-ci.org/markt-de/puppet-nextcloud.png?branch=main)](https://travis-ci.org/markt-de/puppet-nextcloud)
[![Puppet Forge](https://img.shields.io/puppetforge/v/fraenki/nextcloud.svg)](https://forge.puppetlabs.com/fraenki/nextcloud)
[![Puppet Forge](https://img.shields.io/puppetforge/dt/fraenki/nextcloud.svg)](https://forge.puppetlabs.com/fraenki/nextcloud)

#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [Configuring Nextcloud](#configuring-nextcloud)
    - [Managing Apps](#managing-apps)
    - [Configuring Apps](#configuring-apps)
    - [Performing Updates](#performing-updates)
    - [High Performance Backend](#high-performance-backend)
    - [High Availability](#high-availability)
    - [Directory Structure](#directory-structure)
1. [Reference](#reference)
1. [Development](#development)
    - [Contributing](#contributing)
    - [Acknowledgement](#acknowledgement)
1. [License](#license)

## Overview

A Puppet module to install and manage [Nextcloud](https://nextcloud.com/). It is highly configurable, supports Nextcloud apps, automated updates and is suited for multi-server setups.

## Requirements

This module should work with all officially supported versions of Nextcloud.

The focus of this module is Nextcloud, so you should ensure that all additional components are available and ready to use:

A MySQL/MariaDB/PostgreSQL database.

A webservice like Apache or Nginx, [puppetlabs/apache](https://github.com/puppetlabs/puppetlabs-apache) is recommended.

A supported version of PHP (PHP-FPM is strongly recommended). The module is capable of providing a default installation of PHP, if the optional soft dependency [puppet/php](https://github.com/voxpupuli/puppet-php) is available.

A optional Redis installation can also be enabled, provided that the optional soft dependency [puppet/redis](https://github.com/voxpupuli/puppet-redis) is available.

## Usage

### Basic usage

A small number of parameters are required to setup Nextcloud:

```puppet
class { 'nextcloud':
  admin_password => 'suPeRseCreT',
  db_password    => 'secRetPasSwOrd',
  version        => '20.0.4',
}
```

If the database service is not running on the same server, then the database settings need to be adjusted:

```puppet
class { 'nextcloud':
  db_driver      => 'mysql',
  db_host        => 'db.example.com',
  db_name        => 'nextcloud_dbname',
  db_password    => 'secRetPasSwOrd',
  db_user        => 'nextcloud_dbuser',
  ...
}
```

The folder of the Nextcloud installation is derived from three parameters: `$installroot`, `$symlink_name` and `$datadir`. Using different folders is simple:

```puppet
class { 'nextcloud':
  datadir      => '/opt/nextcloud-data',
  installroot  => '/opt',
  symlink_name => 'nextcloud',
  ...
}
```

In this example the Nextcloud installation will live in `/opt/nextcloud`, and this folder should be used as DocumentRoot for the webservice (and/or PHP-FPM). All user-data will be stored in `/opt/nextcloud-data`. Note that `$datadir` MUST NOT be a subdirectory of the installation folder.

Also note that you MUST NOT change these folders after the initial installation of Nextcloud is complete. This is unsupported and will break your installation. However, you can still manually migrate Nextcloud to different folders if you know what you are doing.

A full list of available parameters is available in [REFERENCE.md](REFERENCE.md).

All default values can be found in the `data/` directory.

### Configuring Nextcloud

All entries in `$config` will be added to Nextcloud's configuration:

```puppet
class { 'nextcloud':
  config => {
    mail_smtpmode        => 'smtp',
    mail_smtphost        => 'mail.example.com',
    mail_smtpport        => 25,
    memcache.local       => '\OC\Memcache\APCu',
    memcache.distributed => '\OC\Memcache\Redis',
    memcache.locking     => '\OC\Memcache\Redis',
    overwrite.cli.url    => 'https://nextcloud.example.com/',
    overwritehost        => 'nextcloud.example.com',
    trusted_domains      => [ 'nextcloud.example.com', 'cloud.example.com' ],
    trusted_proxies      => [ '10.0.0.1', '10.0.0.2' ],
  },
  ...
}
```

Every option will be added by using Nextcloud's native config commands. The configuration file will NOT be replaced by this module. This menas that it is still possible to modify Nextcloud's configuration without using Puppet.

Hierarchical settings are also supported:

```puppet
class { 'nextcloud':
  config => {
    app_paths => [
      {
        path => '/opt/nextcloud/apps',
        url => '/apps',
        writable => false
      },
      {
        path => '/opt/nextcloud-user-apps',
        url => '/user-apps',
        writable => false
      }
    ],
    'redis.cluster' => {
      seeds => [
        'redis1.example.com:6379',
        'redis2.example.com:6379',
        'redis3.example.com:6379',
      ],
      timeout => 60,
    },
    ...
  },
  ...
}
```

In case an option needs to be completely _removed_ from the configuration, add the `DELETE:` prefix:

```puppet
class { 'nextcloud':
  config => {
    'DELETE:memcache.distributed' => '\OC\Memcache\Redis',
  },
  ...
}
```

This example would remove the `memcache.distributed` option from the configuration.

*Note:* All settings are added _after_ performing the initial installation of Nextcloud, hence no setting in `$config` will have an affect on the installation process.

### Managing Apps

Nextcloud apps can be installed, removed, enabled and disabled by using the `$apps` parameter:

```puppet
class { 'nextcloud':
  apps => {
    calendar => {
      ensure => present,
      status => disabled,
    },
    contacts => {
      ensure => present,
      status => enabled,
    },
    comments => {
      status => disabled,
    },
    photos => '',
    serverinfo => {},
  },
  ...
}
```

The parameter `ensure` specifies whether the app should be `present` (installed) or `absent` (removed).

The parameter `status` specifies whether the app should be `disabled` or `enabled`.

Both parameters can be ommitted and replaced with an empty string `''` or an empty hash `{}`. In this case the default values will be used (present/enabled).

### Configuring Apps

Nextcloud apps can be configured using the `$app_config` parameter:

```puppet
class { 'nextcloud':
  apps => {
    document_community => {
      ensure => present,
      status => enabled,
    },
    onlyoffice => {
      ensure => present,
      status => enabled,
    },
  },
  app_config => {
    onlyoffice => {
      DocumentServerUrl => "https://${$facts['fqdn']}/index.php/apps/documentserver_community/",
      verify_peer_off: 'true',
    },
  },
}
```

The app name should be the key in the hash and any configuration parameters for that app
should be key/value pairs within.

### Performing Updates

The module will automatically perform updates of Nextcloud when the value of `$version` is changed. An optional post-update command can be specified, which will be executed as root:

```puppet
class { 'nextcloud':
  post_update_cmd => 'systemctl restart php-fpm'
  ...
}
```

Note that the post-update command will run on all servers (up to 30 minutes after the update was installed).

Nextcloud's native upgrade command will also be utilized, but depending on the size of the installation, it may be required to increase the value of `$command_timeout`. The use of the native upgrade command and the post-update command may be disabled by setting `$update_enabled` to `false`, which will allow to perform these steps manually at any time. Note that this does NOT prevent the automatic update, it will only skip the native upgrade and post-update commands. To completely disable all updates, the parameter `$update_enabled` must be set to `none`.

The old installation folder will be preserved. In theory, it should be possible to revert to the previous version if no incompatible (database) change was involved. The official Nextcloud documentation should provide more details.

However, it must be ensured that the upgrade path is supported by Nextcloud prior to attempting an update. Besides that performing a full backup periodically is strongly advised.

### High Performance Backend

The module supports Nextcloud's High Performance Backend that was introduced in Nextcloud 21. To let the module install the "notify_push" app and manage this service, set `$manage_hpb` to `true`.

Keep in mind that you have to manually configure your webserver or reverse proxy to actually use the High Performance Backend. In case of Apache HTTPD, just add the following lines to the <VirtualHost> block used for the Nextcloud server:

```
  ProxyPass /push/ws ws://127.0.0.1:7867/ws
  ProxyPass /push/ http://127.0.0.1:7867/
  ProxyPassReverse /push/ http://127.0.0.1:7867/
```

### High Availability

The module supports highly available setups where multiple servers are used.

In this case the Nextcloud installation and data directory must be stored on a shared storage like NFS. It is crucial that all servers share these folders. Besides that a highly available instance of Redis should be used as memcache to avoid lock/session contention.

All installation and update tasks of this module use lock files to prevent concurrent execution on multiple servers.

### Directory structure

When using the module with default options...

```puppet
class { 'nextcloud':
  datadir      => '/opt/nextcloud-data',
  installroot  => '/opt',
  symlink_name => 'nextcloud',
  version      => '20.0.4',
}
```

...the directory structure will look like this:


```
/
|-- opt/
| |-- nextcloud@                            # symlink to the current install dir (nextcloud-20.0.4)
| |-- nextcloud-20.0.3                      # install dir for a previous version (will not be purged)
| |-- nextcloud-20.0.4                      # install dir for the current version
| | |-- nextcloud                           # default application folder (extracted from dist archive)
| |   |-- config
| |   | |-- config.php@                     # symlink to the real config.php in Nextcloud's data dir
| |-- nextcloud-data                        # Nextcloud's data directory
|     |-- .config.php                       # real config.php (hidden file)
|     |-- .puppet_app.lock                  # indicates that Puppet is currently running a app management command
|     |-- .puppet_convert_filecache.done    # indicates that Puppet completed the "convert filecache" command
|     |-- .puppet_dist_initial_install.done # indicates that the initial install of Nextcloud is done
|     |-- .puppet_missing_indices.done      # indicates that Puppet completed the "missing indices" command
|     |-- .puppet_update_20.0.3.done        # indicates that an update to version 20.0.3 was performed
|     |-- .puppet_update_20.0.4.done        # indicates that an update to version 20.0.4 was performed
|-- var/
| |-- db/
|   |-- nextcloud_data                      # contains the path to Nextcloud's data dir (used by custom fact)
|   |-- nextcloud_home                      # contains the path to Nextcloud's install/home dir (used by custom fact)

```

In this example, Nextcloud was initially installed with version 20.0.3 and later updated to version 20.0.4.

The suffix `.done` indicates that this file is used by the module to identify completed jobs.

The suffix `.lock` indicates that this file is used by the module to identify currently running jobs.

All files that are prefixed with `.puppet_` are required for proper operation of this module and must not be removed.

## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

### Acknowledgement

This module was heavily inspired by [adullact/nextcloud](https://forge.puppet.com/modules/adullact/nextcloud), which was written by Fabien Combernous. Many features would not be available without his hard work.

## License

Copyright 2020 Frank Wall

