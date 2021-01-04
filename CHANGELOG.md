# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [v1.1.0] - 2021-01-04
This release fixes a bug that caused all attempts to perform an update to fail.

### Added
* Add custom fact `nextcloud_dist_jobs`, internally used by `nextcloud::install::distribution`

### Fixed
* Fix updates by changing the workflow in `nextcloud::install::distribution`

## v1.0.0 - 2021-01-01
Initial release

[Unreleased]: https://github.com/markt-de/puppet-nextcloud/compare/v1.0.0...HEAD
[v1.1.0]: https://github.com/markt-de/puppet-nextcloud/compare/v1.0.0...v1.1.0
