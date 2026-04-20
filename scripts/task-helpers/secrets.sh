#!/bin/sh
# ================================================================
# File: scripts/task-helpers/secrets.sh
# Purpose:
#   Shared shell helpers for secrets management tasks.
# Notes:
#   - This file is intended to be sourced by Task shell commands.
#   - It focuses on safe dotenv and encrypted file handling.
#   - It is written to remain portable for /bin/sh execution.
# ================================================================

set -eu

require_command() {
  secrets_cmd="${1:?Missing command name}"
  command -v "$secrets_cmd" >/dev/null 2>&1 || {
    printf 'Required command not found: %s\n' "$secrets_cmd" >&2
    exit 1
  }
}

ensure_parent_dir() {
  secrets_file_path="${1:?Missing file path}"
  mkdir -p "$(dirname "$secrets_file_path")"
}


tty_available() {
  [ -r /dev/tty ] && [ -w /dev/tty ]
}

require_tty() {
  tty_prompt_context="${1:-interactive input}"
  tty_available || {
    printf 'A TTY is required for %s and no interactive terminal is available
' "$tty_prompt_context" >&2
    exit 1
  }
}

tty_prompt() {
  tty_prompt_text="${1:?Missing prompt text}"
  tty_prompt_value=''

  require_tty "$tty_prompt_text"
  printf '%s' "$tty_prompt_text" > /dev/tty
  IFS= read -r tty_prompt_value < /dev/tty || true
  printf '%s' "$tty_prompt_value"
}

tty_prompt_secret() {
  tty_prompt_text="${1:?Missing prompt text}"
  tty_prompt_value=''

  require_tty "$tty_prompt_text"
  printf '%s' "$tty_prompt_text" > /dev/tty
  stty -echo < /dev/tty
  IFS= read -r tty_prompt_value < /dev/tty || true
  stty echo < /dev/tty
  printf '
' > /dev/tty
  printf '%s' "$tty_prompt_value"
}

ensure_env_key_value() {
  secrets_env_file="${1:?Missing env file}"
  secrets_key="${2:?Missing key}"
  secrets_value="${3:?Missing value}"

  [ -f "$secrets_env_file" ] || {
    printf 'Env file not found. Create it first: %s\n' "$secrets_env_file" >&2
    return 1
  }

  if grep -Eq "^${secrets_key}=" "$secrets_env_file"; then
    python3 - "$secrets_env_file" "$secrets_key" "$secrets_value" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]

lines = path.read_text(encoding="utf-8").splitlines()
out = []
updated = False

for line in lines:
    if line.startswith(f"{key}="):
        out.append(f"{key}={value}")
        updated = True
    else:
        out.append(line)

if not updated:
    out.append(f"{key}={value}")

path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PY
  else
    printf '%s=%s\n' "$secrets_key" "$secrets_value" >> "$secrets_env_file"
  fi
}

get_env_value() {
  secrets_env_file="${1:?Missing env file}"
  secrets_key="${2:?Missing key}"

  [ -f "$secrets_env_file" ] || return 1

  awk -F= -v search_key="$secrets_key" '
    $1 == search_key {
      sub(/^[^=]*=/, "")
      print
      exit
    }
  ' "$secrets_env_file"
}

prompt_if_missing_env_key() {
  secrets_env_file="${1:?Missing env file}"
  secrets_key="${2:?Missing key}"
  secrets_prompt_text="${3:?Missing prompt text}"

  secrets_current_value="$(get_env_value "$secrets_env_file" "$secrets_key" || true)"
  if [ -n "$secrets_current_value" ]; then
    printf '%s
' "$secrets_current_value"
    return 0
  fi

  require_tty "$secrets_key"
  secrets_current_value="$(tty_prompt "$secrets_prompt_text")"

  if [ -z "$secrets_current_value" ]; then
    printf 'A value is required for %s
' "$secrets_key" >&2
    exit 1
  fi

  ensure_env_key_value "$secrets_env_file" "$secrets_key" "$secrets_current_value"
  printf '%s
' "$secrets_current_value"
}

sops_decrypt_to_tmp() {
  secrets_encrypted_file="${1:?Missing encrypted file}"
  secrets_key_file="${2:?Missing age key file}"
  secrets_tmp_file="${3:?Missing temp file}"

  SOPS_AGE_KEY_FILE="$secrets_key_file" sops --decrypt "$secrets_encrypted_file" > "$secrets_tmp_file"
  chmod 600 "$secrets_tmp_file"
}

sops_encrypt_from_tmp() {
  secrets_plain_file="${1:?Missing plaintext file}"
  secrets_key_file="${2:?Missing age key file}"
  secrets_output_file="${3:?Missing output file}"
  secrets_input_type="${4:-binary}"
  secrets_output_type="${5:-binary}"
  secrets_filename_override="${6:-}"

  ensure_parent_dir "$secrets_output_file"

  if [ "$secrets_input_type" = "binary" ]; then
    if [ -n "$secrets_filename_override" ]; then
      SOPS_AGE_KEY_FILE="$secrets_key_file" sops \
        --encrypt \
        --filename-override "$secrets_filename_override" \
        "$secrets_plain_file" > "$secrets_output_file"
    else
      SOPS_AGE_KEY_FILE="$secrets_key_file" sops \
        --encrypt \
        "$secrets_plain_file" > "$secrets_output_file"
    fi
  else
    if [ -n "$secrets_filename_override" ]; then
      SOPS_AGE_KEY_FILE="$secrets_key_file" sops \
        --encrypt \
        --filename-override "$secrets_filename_override" \
        --input-type "$secrets_input_type" \
        --output-type "$secrets_output_type" \
        "$secrets_plain_file" > "$secrets_output_file"
    else
      SOPS_AGE_KEY_FILE="$secrets_key_file" sops \
        --encrypt \
        --input-type "$secrets_input_type" \
        --output-type "$secrets_output_type" \
        "$secrets_plain_file" > "$secrets_output_file"
    fi
  fi

  chmod 600 "$secrets_output_file"
}

encrypted_dotenv_upsert() {
  secrets_env_key="${1:?Missing env key}"
  secrets_env_value="${2:?Missing env value}"
  secrets_encrypted_file="${3:?Missing encrypted file}"
  secrets_age_key_file="${4:?Missing age key file}"
  secrets_filename_override="${5:-$secrets_encrypted_file}"

  [ -f "$secrets_age_key_file" ] || {
    printf 'Age key file not found: %s\n' "$secrets_age_key_file" >&2
    return 1
  }

  secrets_tmp_file="$(mktemp)"
  cleanup_encrypted_dotenv_upsert() {
    rm -f "$secrets_tmp_file"
  }

  if [ -f "$secrets_encrypted_file" ]; then
    if SOPS_AGE_KEY_FILE="$secrets_age_key_file" sops --decrypt "$secrets_encrypted_file" > "$secrets_tmp_file" 2>/dev/null; then
      chmod 600 "$secrets_tmp_file"
    else
      cp "$secrets_encrypted_file" "$secrets_tmp_file"
      chmod 600 "$secrets_tmp_file"
    fi
  else
    : > "$secrets_tmp_file"
    chmod 600 "$secrets_tmp_file"
  fi

  if ! ensure_env_key_value "$secrets_tmp_file" "$secrets_env_key" "$secrets_env_value"; then
    cleanup_encrypted_dotenv_upsert
    return 1
  fi

  if ! sops_encrypt_from_tmp \
    "$secrets_tmp_file" \
    "$secrets_age_key_file" \
    "$secrets_encrypted_file" \
    dotenv \
    dotenv \
    "$secrets_filename_override"; then
    cleanup_encrypted_dotenv_upsert
    return 1
  fi

  cleanup_encrypted_dotenv_upsert
  return 0
}