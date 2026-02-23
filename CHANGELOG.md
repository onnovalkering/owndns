# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

## [0.1.0] - 2026-02-23

### Added

- Unbound v1.24.2 recursive resolver with DNSSEC, QNAME minimization, and DNS rebinding protection.
- Ad, tracker, and malware blocking via Hagezi RPZ blocklists (PRO, TIF, NRD, abused TLDs).
- IDN homograph attack protection by blocking punycode (`xn--`) domains.
- Automatic periodic blocklist updates with ETag-based conditional fetching and selective zone reloading.
- DNS-over-HTTPS bootstrap to avoid circular DNS dependency on first boot.
- Nix-built Docker container image running as non-root.
- GitHub Actions CI/CD with GHCR publishing and changelog-based releases.

