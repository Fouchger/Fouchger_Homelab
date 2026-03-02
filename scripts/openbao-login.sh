#!/usr/bin/env bash
# ##################################################################################################
# File: scripts/openbao-login.sh
# Purpose:
#   Interactive OpenBao operator helper:
#     - Decrypt SOPS bootstrap
#     - Extract root token
#     - Optionally display unseal keys for manual copy/paste
#     - Prompt to unseal (3 keys)
#     - Login using root token
# Notes:
#   - Requires: sops, jq, bao
#   - Intended for a real terminal (TTY) so bao can prompt safely.
# ##################################################################################################

set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/root/Github/Fouchger_Homelab}"
AGE_KEY_FILE="${AGE_KEY_FILE:-${ROOT_DIR}/state/secrets/age/age-key.txt}"
BOOTSTRAP_ENC="${BOOTSTRAP_ENC:-${ROOT_DIR}/state/secrets/openbao/bootstrap.enc.yaml}"

export BAO_ADDR="${BAO_ADDR:-https://127.0.0.1:8200}"
export BAO_SKIP_VERIFY="${BAO_SKIP_VERIFY:-true}"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-${AGE_KEY_FILE}}"

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
require_file() { [ -f "$1" ] || { echo "Missing file: $1"; exit 1; }; }

require_cmd sops
require_cmd jq
require_cmd bao

require_file "${SOPS_AGE_KEY_FILE}"
require_file "${BOOTSTRAP_ENC}"

# Must be a terminal for interactive bao prompts
if [ ! -t 0 ]; then
  echo "This script must be run from an interactive terminal (TTY)."
  echo "Run it directly in your SSH session, not via a pipeline or non-interactive runner."
  exit 1
fi

echo "Decrypting bootstrap:"
echo "  ${BOOTSTRAP_ENC}"
echo

DECRYPTED="$(sops -d "${BOOTSTRAP_ENC}")" || {
  echo "Failed to decrypt bootstrap. Check SOPS_AGE_KEY_FILE:"
  echo "  ${SOPS_AGE_KEY_FILE}"
  exit 1
}

# Extract JSON payload from YAML 'json: |' block (indentation-agnostic)
JSON_PAYLOAD="$(
  printf '%s\n' "${DECRYPTED}" | awk '
    found {
      if ($0 ~ /^[^[:space:]]/) exit
      sub(/^[[:space:]]+/, "", $0)
      print
    }
    /^[[:space:]]*json:[[:space:]]*\|[[:space:]]*$/ { found=1; next }
  '
)"

if [ -z "${JSON_PAYLOAD}" ]; then
  echo "Could not locate JSON payload under 'json: |' in bootstrap."
  echo "Showing first 80 lines of decrypted file for troubleshooting:"
  printf '%s\n' "${DECRYPTED}" | sed -n '1,80p'
  exit 1
fi

ROOT_TOKEN="$(printf '%s\n' "${JSON_PAYLOAD}" | jq -r '.root_token // empty' 2>/dev/null || true)"
if [ -z "${ROOT_TOKEN}" ] || [ "${ROOT_TOKEN}" = "null" ]; then
  echo "Could not extract root_token from JSON payload."
  echo "JSON payload (first 40 lines):"
  printf '%s\n' "${JSON_PAYLOAD}" | sed -n '1,40p'
  exit 1
fi

echo "Root token extracted."
echo

# Offer to display unseal keys for copy/paste
read -r -p "Display unseal keys now (so you can paste them into prompts)? [y/N] " SHOW_KEYS
if [[ "${SHOW_KEYS}" =~ ^[Yy]$ ]]; then
  echo
  echo "Unseal keys (base64):"
  printf '%s\n' "${JSON_PAYLOAD}" | jq -r '.unseal_keys_b64[]'
  echo
  echo "Keep these safe. You need 3 different keys to unseal."
  echo
fi

echo "Checking OpenBao status at ${BAO_ADDR} ..."
bao status || true
echo

SEALED="$(bao status -format=json 2>/dev/null | jq -r '.sealed // empty' || true)"
if [ -z "${SEALED}" ]; then
  if bao status 2>/dev/null | grep -qi 'Sealed.*true'; then
    SEALED="true"
  else
    SEALED="false"
  fi
fi

if [ "${SEALED}" = "true" ]; then
  echo "OpenBao is sealed. You will be prompted 3 times for unseal keys."
  echo "Paste a different key each time."
  echo
  bao operator unseal
  bao operator unseal
  bao operator unseal
  echo
else
  echo "OpenBao is already unsealed."
  echo
fi

echo "Logging in (this sets your token for this shell session)..."
bao login "${ROOT_TOKEN}" >/dev/null

echo "Login successful. Token summary:"
bao token lookup | sed -n '1,25p'