# OwnDNS
An opinionated mashup of existing open-source DNS efforts, packaged for easy self-hosting.

## Features

- [Unbound](https://nlnetlabs.nl/projects/unbound/about/) (v1.24.2) as recursive resolver (queries root servers directly, not a forwarder).
    - DNSSEC validation with automatic trust anchor management and aggressive NSEC.
    - QNAME minimization and identity hiding for query privacy, with no query logging by default.
    - Cache with minimum TTL and prefetching to keep popular domains warm as TTLs expire.
    - DNS rebinding protection via `private-address` directives.
- Integrated DNS blocking via [Hagezi](https://github.com/hagezi/dns-blocklists) response policy zone (RPZ) files.
    - Blocks ads, crytojacking, malware, scams, phishing, and trackers ([PRO](https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#pro), [TIF](https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#tif)).
    - Blocks newly registered domains ([NRD](https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#capital_abcd-entropy-nrdsdgas-contain-only-newly-registered-high-entropy-domains-generated-by-domain-generation-algorithms-dgas)) and most abused [TLDs](https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#crystal_ball-most-abused-tlds---protects-against-known-malicious-top-level-domains-recommended-).
- Automatic periodic blocklist updates with ETag-based conditional fetching and selective reloading.
- Bootstrap with DNS-over-HTTPS resolution to avoid circular DNS dependency on first boot.


### Roadmap

- [ ] IDN homograph attack protection by blocking punycode (`xn--`) domains.
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
| `BOOTSTRAP_DOH_URL` | `https://9.9.9.9/dns-query` | DNS-over-HTTPS URL used during initial blocklist fetch. |
| `UPDATE_INTERVAL_HOURS` | `6` | Hours between blocklist refresh cycles. |

