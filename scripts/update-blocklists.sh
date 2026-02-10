#!/bin/bash
set -euo pipefail

: "${BOOTSTRAP_DOH_URL:=https://9.9.9.9/dns-query}"
: "${HAGEZI_NDR_FILEPATH:=/etc/unbound/rpz/ndr.txt}"
: "${HAGEZI_NDR_URL:=https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/dga7.txt}"
: "${HAGEZI_PRO_FILEPATH:=/etc/unbound/rpz/pro.txt}"
: "${HAGEZI_PRO_URL:=https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.txt}"
: "${HAGEZI_TIF_FILEPATH:=/etc/unbound/rpz/tif.txt}"
: "${HAGEZI_TIF_URL:=https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/tif.txt}"
: "${HAGEZI_TLD_FILEPATH:=/etc/unbound/rpz/tld.txt}"
: "${HAGEZI_TLD_URL:=https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/spam-tlds-rpz.txt}"

bootstrap=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap) bootstrap=true; shift ;;
    *)
      shift
      ;;
  esac
done

timestamp() {
  LC_TIME=C date "+%b %e %H:%M:%S"
}

function log() {
  echo "$(timestamp) update-blocklists[$$] info: $*"
}

function err() {
  echo "$(timestamp) update-blocklists[$$] error: $*" >&2
}

function get_etag_from_response() {
  local response="$1"

  while IFS= read -r line; do
    if [[ "${line,,}" == etag:* ]]; then
      local value="${line#*: }"
      value="${value%$'\r'}"
      echo "$value"
      return 0
    fi
  done <<< "$response"

  return 1
}

function update_blocklist() {
  local remote_url="$1"
  local local_file="$2"
  local etag_file="$3"
  local convert="${4:-false}"

  local temp_file=$(mktemp)
  trap 'rm -f "$temp_file"' RETURN

  local local_etag=""
  local remote_etag=""

  # Prepare etag value for If-None-Match header.
  # Force fresh download if local file is missing.
  [[ ! -f "$local_file" ]] && rm -f "$etag_file"
  [[ -f "$etag_file" ]] && local_etag=$(<"$etag_file")

  # When bootstrapping use a DoH endpoint to resolve domains.
  local doh_args=()
  if "$bootstrap"; then
    doh_args=(--doh-url "$BOOTSTRAP_DOH_URL")
  fi

  local response=$(curl \
    --fail --silent --show-error --location --remote-time \
    --retry 3 --retry-delay 5 --connect-timeout 10 --max-time 120 \
    --header "If-None-Match: $local_etag" --dump-header - \
    --write-out "%{http_code}" --output "$temp_file" \
    "${doh_args[@]+"${doh_args[@]}"}" "$remote_url"
  )

  local http_code="${response: -3}"
  case "$http_code" in
    200)
      if "$convert"; then
        log "Converting domain file to RPZ file..."
        convert_domain_file_to_rpz_file_inplace "$temp_file"
      fi

      mv "$temp_file" "$local_file"

      # Overwrite local etag with remote etag in etag file.
      remote_etag=$(get_etag_from_response "$response") || true
      [[ -n "$remote_etag" ]] && echo "$remote_etag" > "$etag_file"

      log "$remote_etag"

      log "Update complete: $local_file"
      return 0
      ;;
    304)
      log "Update skipped: $local_file (Not Modified)"
      return 2
      ;;
    *)
      err "Update failed: $local_file (HTTP $http_code)"
      return 1
      ;;
  esac
}

function convert_domain_file_to_rpz_file_inplace() {
  local domain_file="$1"

  if [ ! -f "$domain_file" ]; then
    err "Domain file $domain_file not found."
    return 1
  fi

  local temp_file=$(mktemp)
  trap 'rm -f "$temp_file"' RETURN

  local serial
  serial=$(date +%s)

  awk -v serial="$serial" '
    BEGIN {
      print "$TTL 300"
      print "@  SOA localhost. root.localhost. " serial " 43200 3600 86400 300"
      print "   NS  localhost."
    }

    # Skip comments (lines starting with #) and empty lines
    /^#/ || /^[[:space:]]*$/ { next }

    { print $1 ".rpz.nrd. IN CNAME ." }
  ' "$domain_file" > "$temp_file"

  mv "$temp_file" "$domain_file"

  return 0
}

# This will affect the exit code of this script, allowing the Unbound
# daemon to be conditionally reloaded only when blockist updates occur.
updated=false

update_blocklist \
  "$HAGEZI_NDR_URL" \
  "$HAGEZI_NDR_FILEPATH" \
  "$HAGEZI_NDR_FILEPATH.etag" \
  true \
  && updated=true

update_blocklist \
  "$HAGEZI_PRO_URL" \
  "$HAGEZI_PRO_FILEPATH" \
  "$HAGEZI_PRO_FILEPATH.etag" \
  && updated=true

update_blocklist \
  "$HAGEZI_TIF_URL" \
  "$HAGEZI_TIF_FILEPATH" \
  "$HAGEZI_TIF_FILEPATH.etag" \
  && updated=true

update_blocklist \
  "$HAGEZI_TLD_URL" \
  "$HAGEZI_TLD_FILEPATH" \
  "$HAGEZI_TLD_FILEPATH.etag" \
  && updated=true

if "$updated"; then
  exit 0
else
  exit 2
fi


