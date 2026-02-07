#!/bin/bash
set -euo pipefail

: "${UNBOUND_CONFIG_FILEPATH:=/etc/unbound/unbound.conf}"
: "${UPDATE_INTERVAL_HOURS:=6}"

function log() {
  echo "$(date -Iseconds) [entrypoint] $*"
}

function err() {
  echo "$(date -Iseconds) [entrypoint] $*" >&2
}

function run_unbound() {
  log "Starting unbound..."
  /bin/unbound -d -c "$1" &
}

function run_updates() {
  local interval_hours="$1"
  local interval_seconds=$(($1 * 3600))

  log "Running update every ${interval_hours} hours."

  while true; do
    sleep "$interval_seconds"
    log "Running update..."

    /bin/update-blocklists && rc=0 || rc=$?

    case "$rc" in
      0)
        log "Reloading unbound..."
        if ! unbound-control reload; then
          err "Failed to reload unbound."
        fi
        ;;
      1)
        err "Failed to update blocklists."
        ;;
      *)
        ;;
    esac
  done
}

function shutdown() {
  log "Shutting down..."

  kill "$UPDATES_PID" 2>/dev/null || true
  kill "$UNBOUND_PID" 2>/dev/null || true
  wait "$UNBOUND_PID" 2>/dev/null

  exit 0
}

# An initial update is required because the blocklists
# are not embedded into the OwnDNS container image.
if ! /bin/update-blocklists; then
  err "Failed to perform initial blocklist update."
fi

run_unbound "$UNBOUND_CONFIG_FILEPATH"
UNBOUND_PID=$!

run_updates "$UPDATE_INTERVAL_HOURS" &
UPDATES_PID=$!

trap shutdown SIGTERM SIGINT
wait "$UNBOUND_PID"

