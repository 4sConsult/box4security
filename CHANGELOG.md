# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.5] - 2020-12-17
### Changed 
* Use NVD Vulnerability Severity Ratings (CVSS) Ranges. Previously custom vulnerability ranges were used.
* `VERSION` file is now stored under fixed path `/var/lib/box4s`. Only modify if you know what you're doing (`BOX4s_ENV=dev` toggles the development mode).
* When using insecure default secrets (i.e. unchanged prior to installation), these are replaced by randomly generated secrets that are also printed at the end of the installation script. Save them, if you need to.
### Fixed
* Fixed parts of the update script, which didn't use changed directories yet.


## [0.0.4] - 2020-12-16
Separate installation, configuration from the cloned repository.

### Added
* New environment variables `$BOX4s_INSTALL_DIR` and `$BOX4s_CONFIG_DIR` are available, resolving to the installation and configuration directory respectively.

### Changed 
* Installation is now performed (by default) to `/opt/box4s`. The config files (secrets!) are by default copied from the local repos folder to `/etc/box4s` during installation. **Change secrets before running install script!**
* Installation no longer restarts the OpenVAS container. This became obsolete with recent OpenVAS image updates. Updates are performed with each start, so also with the first.


## [0.0.3] - 2020-12-15
First publicly from GitHub installable release.

### Fixed
- Fix errors in installation script `install.sh` that came up when installing from the public GitHub repository.



## [0.0.2] - 2020-12-15
Refactor Container to Host communication.

### Changed
- Use Docker API and named UNIX pipe to communicate from web to host and other containers.


## [0.0.1] - 2020-12-10
First Open Source release to the public domain.

### Changed
- Installation no longer requires a deploy secret.
- Installation now references Docker images stored in public Docker-Hub repositories.
- Secret files no longer are encrypted under a PGP key, but are instead changed to a default value of `CHANGEME` that **must** be changed when install.
