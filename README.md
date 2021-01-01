# puppet-nextcloud

[![Build Status](https://travis-ci.org/markt-de/puppet-nextcloud.png?branch=master)](https://travis-ci.org/markt-de/puppet-nextcloud)
[![Puppet Forge](https://img.shields.io/puppetforge/v/fraenki/nextcloud.svg)](https://forge.puppetlabs.com/fraenki/nextcloud)
[![Puppet Forge](https://img.shields.io/puppetforge/f/fraenki/nextcloud.svg)](https://forge.puppetlabs.com/fraenki/nextcloud)

#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [Configure Nextcloud](#configure-nextcloud)
    - [Manage Apps](#manage-apps)
    - [Performing Updates](#performing-updates)
    - [High Availability](#high-availability)
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

### Configure Nextcloud

All entries in `$config` will be added to Nextcloud's configuration:

```puppet
class { 'nextcloud':
  config => {
    mail_smtpmode        => 'smtp',
    mail_smtphost        => 'mail.example.com',
    mail_smtpport        => 25,
    memcache.local       => '\\OC\\Memcache\\Redis',
    memcache.distributed => '\\OC\\Memcache\\Redis',
    memcache.locking     => '\\OC\\Memcache\\Redis',
    overwrite.cli.url    => 'https://nextcloud.example.com/',
    overwritehost        => 'nextcloud.example.com',
    trusted_domains      => [ 'nextcloud.example.com', 'cloud.example.com' ],
    trusted_proxies      => [ '10.0.0.1', '10.0.0.2' ],
  },
  ...
}
```

Every option will be added by using Nextcloud's native config commands. The configuration file will NOT be replaced by this module. This menas that it is still possible to modify Nextcloud's configuration without using Puppet.

In case an option needs to be completely _removed_ from the configuration, add the `DELETE:` prefix:

```puppet
class { 'nextcloud':
  config => {
    'DELETE:memcache.distributed' => '\\OC\\Memcache\\Redis',
  },
  ...
}
```

This example would remove the `memcache.distributed` option from the configuration.

*Note:* All settings are added _after_ performing the initial installation of Nextcloud, hence no setting in `$config` will have an affect on the installation process.

### Manage Apps

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

### Performing Updates

The module will automatically perform updates of Nextcloud when the value of `$version` is changed. Nextcloud's native upgrade command will also be utilized, but depending on the size of the installation, it may be required to increase the value of `$command_timeout`. The use of the native upgrade command may be disabled by setting `$update_enabled` to `false`, which will allow to perform this step manually at any time. Note that this does NOT prevent the automatic update, it will only skip the native upgrade command. To completely disable all updates, the parameter `$update_enabled` must be set to `none`.

The old installation folder will be preserved. In theory, it should be possible to revert to the previous version if no incompatible (database) change was involved. The official Nextcloud documentation should provide more details.

However, it must be ensured that the upgrade path is supported by Nextcloud prior to attempting an update. Besides that performing a full backup periodically is strongly advised.

### High Availability

The module supports highly available setups where multiple servers are used.

In this case the Nextcloud installation and data directory must be stored on a shared storage like NFS. It is crucial that all servers share these folders. Besides that a highly available instance of Redis should be used as memcache to avoid lock/session contention.

All installation and update tasks of this module use lock files to prevent concurrent execution on multiple servers.

## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

### Acknowledgement

This module was heavily inspired by [adullact/nextcloud](https://forge.puppet.com/modules/adullact/nextcloud), which was written by Fabien Combernous. Many features would not be available without his hard work.

## License

Copyright 2020 Frank Wall

