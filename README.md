# OwnDNS
An opinionated mashup of existing open-source DNS efforts, packaged for easy self-hosting.

## Features

- [Unbound](https://nlnetlabs.nl/projects/unbound/about/) (v1.24.2) as recursive resolver (queries root servers directly, not a forwarder).
- DNSSEC validation with automatic trust anchor management and aggressive NSEC.
- QNAME minimization and identity hiding for query privacy, with no query logging by default.
- Ad, cryptojacking, malware, and tracker blocking via [Hagezi](https://github.com/hagezi/dns-blocklists) RPZ blocklists (Pro + TIF).
- Cache prefetching keeps popular domains warm as TTLs expire.
- Automatic periodic blocklist updates with ETag-based conditional fetching.
- Bootstrap with DNS-over-HTTPS resolution to avoid circular DNS dependency on first boot.


### Roadmap

- [ ] DNS rebinding protection via `private-address` directives.
- [ ] Newly Registered Domains (NRD) blocking via Hagezi 14-day list.
- [ ] IDN homograph attack protection by blocking punycode (`xn--`) domains.
- [ ] Most Abused TLDs blocking via Hagezi RPZ list.
- [ ] Custom allow/deny lists and DNS rewrites via config volume mount.

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
| `BOOTSTRAP_DOH_URL` | `https://9.9.9.9/dns-query` | DNS-over-HTTPS URL used for name resolution during initial blocklist fetch.<br><br>Set to empty to disable. |
| `HAGEZI_PRO_URL` | [Hagezi Pro RPZ](https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.txt) | URL for the Hagezi Pro blocklist. |
| `HAGEZI_TIF_URL` | [Hagezi TIF RPZ](https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/tif.txt) | URL for the Hagezi TIF blocklist. |
| `UNBOUND_CONFIG_FILEPATH` | `/etc/unbound/unbound.conf` | Path to the Unbound configuration file. |
| `UPDATE_INTERVAL_HOURS` | `6` | Hours between blocklist refresh cycles. |


