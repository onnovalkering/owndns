# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

## [0.1.0] - 2026-02-07

### Added

- Recursive DNS resolution using Unbound (queries root servers directly).
- DNSSEC validation with automatic trust anchor management.
- QNAME minimization and 0x20 mixed-case encoding.
- Ad, tracker, and malware blocking via Hagezi RPZ blocklists (Pro + TIF).
- Cache prefetching for popular domains.
- Automatic periodic blocklist updates with ETag-based conditional fetching.
- Nix-based Docker image build via `nix build`.
- Non-root container execution (runs as `unbound` user).
- Graceful shutdown handling (SIGTERM/SIGINT).
