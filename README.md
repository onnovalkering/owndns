# OwnDNS
Private DNS Server intended to be self-hosted.

## Features

- [Unbound](https://nlnetlabs.nl/projects/unbound/about/) as recursive resolver (queries root servers directly, not a forwarder).
- DNSSEC validation with automatic trust anchor management.
- QNAME minimization for query privacy and mixed-case encoding for anti-spoofing.
- Ad, tracker, and malware blocking via [Hagezi](https://github.com/hagezi/dns-blocklists) RPZ blocklists (Pro + TIF).
- Cache prefetching keeps popular domains warm as TTLs expire.
- Automatic periodic blocklist updates with ETag-based conditional fetching.

## Build

```sh
nix build
```

The image artifact is stored in `result`. Load it into Docker:

```sh
docker load < result
```

The image is tagged with the short git revision, or `dirty` for uncommitted trees.

## Run
TODO

## Configuration

The following environment variables can be used to configure the container:

| Variable | Default | Description |
|---|---|---|
| `UNBOUND_CONFIG_FILEPATH` | `/etc/unbound/unbound.conf` | Path to the Unbound configuration file. |
| `UPDATE_INTERVAL_HOURS` | `6` | Hours between blocklist refresh cycles. |
| `HAGEZI_PRO_URL` | [Hagezi Pro RPZ](https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.txt) | URL for the Hagezi Pro blocklist. |
| `HAGEZI_PRO_FILEPATH` | `/etc/unbound/rpz/pro.txt` | Local path for the Pro blocklist. |
| `HAGEZI_TIF_URL` | [Hagezi TIF RPZ](https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/tif.txt) | URL for the Hagezi TIF blocklist. |
| `HAGEZI_TIF_FILEPATH` | `/etc/unbound/rpz/tif.txt` | Local path for the TIF blocklist. |

