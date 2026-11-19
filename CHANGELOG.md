# Changelog

All notable changes to PHP+OCI8 docker image will be documented in this file

## 2.0 - 19/11/2026
- Based on PHP 7.4 (`php:7.4-fpm-bullseye`, Debian 11) instead of PHP 7.3.
- PHP is rebuilt from php-src branch `PHP-7.4-CVE-2026-109618-109619` with
  backported fixes from `patches/` for CVE-2026-126714, CVE-2026-129289 and
  CVE-2026-129496.
- CVE-2026-109618 / CVE-2026-109619 / CVE-2026-115560 mitigations in
  `custom.ini` and the FPM pool config (incl. `session.upload_progress.enabled`
  off).
- The image is built for `linux/amd64` only.

## 1.5 - 25/05/2019
- Removed unnecessary time reconfiguration from apt.