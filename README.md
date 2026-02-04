# OwnDNS
Private DNS server based on Unbound.

## Build

```sh
nix build
```

The image artifact is stored in `result`. Load it into Docker:

```sh
docker load < result
```

## Configuration
The DNS server can be configured with environment variables:

- `BLOCKLIST_UPDATE_INTERVAL` (default `12h`) controls how often OISD and root hints refresh.
- `OISD_URL_OVERRIDE` overrides the default OISD source.
- `UNBOUND_VERBOSITY` sets Unbound verbosity level.

## Notes

- Recursive resolver mode with DNSSEC and QNAME minimization enabled.
- Cache prefetching keeps popular domains warm as TTLs expire.
- OISD is fetched on first boot and refreshed periodically at runtime.

