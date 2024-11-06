# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [UNRELEASED]

### Fixed
* Properly handle float/integer values in app/system configuration

## [v1.10.0] - 2023-08-01

### Changed
* Update module dependencies

### Fixed
* Parameter `$install_enabled` is ignored (treated as always true) ([#11])

## [v1.9.0] - 2023-07-25

### Changed
* Update module dependencies and OS support
* Update PDK to 3.0

### Fixed
* Fix GitHub Actions
* Fix compatibility with puppetlabs/stdlib v9.0.0

## [v1.8.3] - 2022-11-05

### Changed
* Run all config commands on the specified host when `$update_host` is set

## [v1.8.2] - 2022-11-05

### Changed
* Run all app commands on the specified host when `$update_host` is set

## [v1.8.1] - 2022-11-05

### Changed
* Change working directory for post update commands to the symlink

### Fixed
* Fix error running post update commands on other hosts when `$update_host` is specified

## [v1.8.0] - 2022-11-05

### Added
* Add new parameter `$update_host`
* Add documentation for all parameters

### Changed
* Only extract the Nextcloud tarball when `$install_enabled` is set to `true`

### Fixed
* Post update command was not run if `$update_enabled` was set to `false`

## [v1.7.0] - 2022-09-21

### Changed
* Update OS versions and Puppet versions
* Update PDK from 1.8.0 to 2.5.0
* Fix puppet-lint offenses

## [v1.6.0] - 2021-03-29

### Added
* Add support for Nextcloud's High Performance Backend (notify_push) ([#5])

### Fixed
* Do not convert boolean config values to strings when passing them to occ

## [v1.5.0] - 2021-02-26

### Added
* Add optional post-update command

## [v1.4.0] - 2021-02-23

### Added
* Add support for hierarchical settings ([#1])

### Fixed
* Properly escape passwords in shell commands ([#4])

## [v1.3.0] - 2021-01-25

### Added
* Add ability to configure Nextcloud apps ([#3])

## [v1.2.0] - 2021-01-20

### Changed
* Make the default cron job silent

## [v1.1.0] - 2021-01-10
This release fixes bugs that caused updates to fail.

### Added
* Add custom fact `nextcloud_dist_jobs`, internally used by `nextcloud::install::distribution`
* Add custom fact `nextcloud_updates`, it lists all completed Nextcloud updates

### Changed
* Reinstall all 3rd-party apps after performing an update of Nextcloud
* Show a client-side warning if app management was forcefully disabled
* Document folder structure

### Fixed
* Fix updates by changing the workflow in `nextcloud::install::distribution`
* Fix missing 3rd-party apps after performing an update of Nextcloud
* Fix execution of `occ db:convert-filecache-bigint` on initial install

## v1.0.0 - 2021-01-01
Initial release

[Unreleased]: https://github.com/markt-de/puppet-nextcloud/compare/v1.10.0...HEAD
[v1.10.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.9.0...v1.10.0
[v1.9.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.8.3...v1.9.0
[v1.8.3]: https://github.com/markt-de/puppet-nextcloud/compare/v1.8.2...v1.8.3
[v1.8.2]: https://github.com/markt-de/puppet-nextcloud/compare/v1.8.1...v1.8.2
[v1.8.1]: https://github.com/markt-de/puppet-nextcloud/compare/v1.8.0...v1.8.1
[v1.8.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.7.0...v1.8.0
[v1.7.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.6.0...v1.7.0
[v1.6.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.5.0...v1.6.0
[v1.5.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.4.0...v1.5.0
[v1.4.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.0.0...v1.1.0
[#11]: https://github.com/markt-de/puppet-nextcloud/pull/11
[#5]: https://github.com/markt-de/puppet-nextcloud/pull/5
[#4]: https://github.com/markt-de/puppet-nextcloud/pull/4
[#3]: https://github.com/markt-de/puppet-nextcloud/pull/3
[#1]: https://github.com/markt-de/puppet-nextcloud/pull/1
