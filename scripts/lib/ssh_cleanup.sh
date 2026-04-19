#!/usr/bin/env bash
# ssh_cleanup.sh
#
# Purpose:
# - Remove stale host keys from known_hosts
# - Re-scan and re-add current host keys
# - Optionally deduplicate known_hosts
# - Optionally remove matching entries from authorized_keys
#
# Usage examples:
#   ./ssh_cleanup.sh --host 192.168.20.10
#   ./ssh_cleanup.sh --host proxmox01.home.local --port 22
#   ./ssh_cleanup.sh --host 192.168.20.10 --authorized-match "old-laptop"
#   ./ssh_cleanup.sh --host 192.168.20.10 --user root --known-hosts /root/.ssh/known_hosts
#
# Notes:
# - This script updates the local machine's known_hosts file.
# - It only edits authorized_keys if --authorized-match is provided.
# - Always review changes before using broad match patterns.

set -euo pipefail

HOST=""
PORT="22"
SSH_USER="${USER:-root}"
KNOWN_HOSTS_FILE="${HOME}/.ssh/known_hosts"
AUTHORIZED_KEYS_FILE="${HOME}/.ssh/authorized_keys"
AUTHORIZED_MATCH=""
READD_HOST_KEY="yes"
DEDUPE_KNOWN_HOSTS="yes"

usage() {
  cat <<'EOF'
Usage:
  ssh_cleanup.sh --host <hostname_or_ip> [options]

Required:
  --host <value>                  Hostname or IP to clean from known_hosts

Optional:
  --port <value>                  SSH port to scan, default: 22
  --user <value>                  SSH user context, default: current user
  --known-hosts <path>            Path to known_hosts file
  --authorized-keys <path>        Path to authorized_keys file
  --authorized-match <pattern>    Remove lines from authorized_keys matching this text
  --no-readd                      Do not re-add current host key after removal
  --no-dedupe                     Do not deduplicate known_hosts
  --help                          Show this help

Examples:
  ssh_cleanup.sh --host 192.168.20.10
  ssh_cleanup.sh --host proxmox01.home.local --port 22
  ssh_cleanup.sh --host 192.168.20.10 --authorized-match "old-laptop"
EOF
}

log() {
  printf '%s\n' "$*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

backup_file() {
  local file_path="$1"
  if [ -f "$file_path" ]; then
    cp "$file_path" "${file_path}.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

ensure_ssh_dir() {
  local parent_dir
  parent_dir="$(dirname "$KNOWN_HOSTS_FILE")"
  mkdir -p "$parent_dir"
  chmod 700 "$parent_dir"

  if [ ! -f "$KNOWN_HOSTS_FILE" ]; then
    touch "$KNOWN_HOSTS_FILE"
    chmod 600 "$KNOWN_HOSTS_FILE"
  fi

  if [ ! -f "$AUTHORIZED_KEYS_FILE" ]; then
    touch "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
  fi
}

remove_from_known_hosts() {
  local target="$1"
  if [ -f "$KNOWN_HOSTS_FILE" ]; then
    ssh-keygen -R "$target" -f "$KNOWN_HOSTS_FILE" >/dev/null 2>&1 || true
    ssh-keygen -R "[$target]:$PORT" -f "$KNOWN_HOSTS_FILE" >/dev/null 2>&1 || true
  fi
}

readd_host_key() {
  local scan_output
  local temp_file

  temp_file="$(mktemp)"
  if ssh-keyscan -T 5 -p "$PORT" "$HOST" >"$temp_file" 2>/dev/null; then
    if [ -s "$temp_file" ]; then
      cat "$temp_file" >>"$KNOWN_HOSTS_FILE"
      log "Re-added current host key for $HOST:$PORT"
    else
      log "Host key scan returned no data for $HOST:$PORT"
    fi
  else
    log "Host key scan failed for $HOST:$PORT"
  fi
  rm -f "$temp_file"
}

dedupe_known_hosts() {
  local temp_file
  temp_file="$(mktemp)"
  awk '!seen[$0]++' "$KNOWN_HOSTS_FILE" >"$temp_file"
  mv "$temp_file" "$KNOWN_HOSTS_FILE"
  chmod 600 "$KNOWN_HOSTS_FILE"
  log "Deduplicated known_hosts"
}

cleanup_authorized_keys() {
  local pattern="$1"
  local temp_file

  if [ -z "$pattern" ]; then
    return 0
  fi

  backup_file "$AUTHORIZED_KEYS_FILE"

  temp_file="$(mktemp)"
  grep -F -v "$pattern" "$AUTHORIZED_KEYS_FILE" >"$temp_file" || true
  mv "$temp_file" "$AUTHORIZED_KEYS_FILE"
  chmod 600 "$AUTHORIZED_KEYS_FILE"
  log "Removed authorized_keys entries matching: $pattern"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    --port)
      PORT="${2:-22}"
      shift 2
      ;;
    --user)
      SSH_USER="${2:-$SSH_USER}"
      shift 2
      ;;
    --known-hosts)
      KNOWN_HOSTS_FILE="${2:-$KNOWN_HOSTS_FILE}"
      shift 2
      ;;
    --authorized-keys)
      AUTHORIZED_KEYS_FILE="${2:-$AUTHORIZED_KEYS_FILE}"
      shift 2
      ;;
    --authorized-match)
      AUTHORIZED_MATCH="${2:-}"
      shift 2
      ;;
    --no-readd)
      READD_HOST_KEY="no"
      shift
      ;;
    --no-dedupe)
      DEDUPE_KNOWN_HOSTS="no"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$HOST" ]; then
  printf 'Error: --host is required\n' >&2
  usage
  exit 1
fi

require_command ssh-keygen
require_command ssh-keyscan
require_command awk
require_command grep

ensure_ssh_dir
backup_file "$KNOWN_HOSTS_FILE"

log "Cleaning known_hosts entries for: $HOST"
remove_from_known_hosts "$HOST"

if [ "$READD_HOST_KEY" = "yes" ]; then
  readd_host_key
fi

if [ "$DEDUPE_KNOWN_HOSTS" = "yes" ]; then
  dedupe_known_hosts
fi

cleanup_authorized_keys "$AUTHORIZED_MATCH"

log "Done."