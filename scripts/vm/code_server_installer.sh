#!/usr/bin/env bash

# ============================================================
# File: scripts/code_server_installer.sh
# Purpose:
#   Install code-server, create a first-run configuration when
#   needed, and store the bootstrap password in the repo-managed
#   encrypted passwords file when the repo secrets standard is
#   available locally.
#
# Notes:
#   - Intended for Debian and Ubuntu style environments with systemd
#   - Refuses to run on a Proxmox host or Alpine
#   - Preserves an existing code-server config if present
#   - Prompts for a password on first install when interactive
#   - Generates a random password in non-interactive mode
# ============================================================

set -Eeuo pipefail

APP="Coder code-server"
VERSION="4.114.0"
CONFIG_DIR="${HOME}/.config/code-server"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
HOSTNAME_SHORT="$(hostname)"
IP_ADDRESS="$(hostname -I 2>/dev/null | awk '{print $1}')"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_HELPERS_FILE="${REPO_ROOT}/scripts/task_helpers.sh"
PASSWORDS_ENC_ENV_FILE="${REPO_ROOT}/state/secrets/passwords/passwords.enc.env"
PASSWORDS_ENC_ENV_FILE_REL="state/secrets/passwords/passwords.enc.env"
AGE_KEYS_FILE="${REPO_ROOT}/state/secrets/age/keys.txt"
PASSWORD_KEY="CODE_SERVER_PASSWORD"
CODE_SERVER_PASSWORD=""
NONINTERACTIVE="${NONINTERACTIVE:-0}"

YW='\033[33m'
BL='\033[36m'
RD='\033[01;31m'
GN='\033[1;92m'
CL='\033[m'
BFR='\r\033[K'
HOLD='-'
CM="${GN}✓${CL}"

trap 'error_exit "Command failed at line ${LINENO}"' ERR

header_info() {
  cat <<'EOF'
   ______          __        _____
  / ____/___  ____/ /__     / ___/___  ______   _____  _____
 / /   / __ \/ __  / _ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
/ /___/ /_/ / /_/ /  __/   ___/ /  __/ /   | |/ /  __/ /
\____/\____/\__,_/\___/   /____/\___/_/    |___/\___/_/

EOF
}

error_exit() {
  local reason="${1:-Unknown failure occurred.}"
  echo -e "${RD}ERROR${CL} ${reason}" >&2
  exit 1
}

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}...${CL}"
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

ensure_not_proxmox_host() {
  if command -v pveversion >/dev/null 2>&1; then
    echo "Cannot install on a Proxmox host" >&2
    exit 1
  fi
}

ensure_not_alpine() {
  if [[ -e /etc/alpine-release ]]; then
    echo "Cannot install on Alpine" >&2
    exit 1
  fi
}

confirm_install() {
  if [[ "${NONINTERACTIVE}" == "1" ]]; then
    return 0
  fi

  while true; do
    read -r -p "This will install ${APP} ${VERSION} on ${HOSTNAME_SHORT}. Proceed (y/n)? " yn
    case "${yn}" in
      [Yy]*) return 0 ;;
            [Nn]*) exit 0 ;;
            *) echo "Please answer y or n." ;;
          esac
  done
}

install_dependencies() {
  msg_info "Installing dependencies"
  apt-get update -qq
  apt-get install -y -qq curl ca-certificates openssl
  msg_ok "Installed dependencies"
}

install_code_server() {
  msg_info "Installing ${APP} v${VERSION}"
  curl -fsSL https://code-server.dev/install.sh | sh -s -- --version "${VERSION}"
  msg_ok "Installed ${APP} v${VERSION}"
}

generate_random_password() {
  openssl rand -base64 24 | tr -d '\n'
}

prompt_for_password() {
  if [[ ! -t 0 ]]; then
    return 1
  fi

  if [[ -f "${TASK_HELPERS_FILE}" ]]; then
    # shellcheck disable=SC1090
    . "${TASK_HELPERS_FILE}"
    prompt_secret_confirm 'code-server password: ' 'Confirm code-server password: '
    return 0
  fi

  return 1
}

set_bootstrap_password() {
  if [[ -n "${CODE_SERVER_PASSWORD}" ]]; then
    return 0
  fi

  if [[ "${NONINTERACTIVE}" != "1" ]]; then
    CODE_SERVER_PASSWORD="$(prompt_for_password || true)"
  fi

  if [[ -z "${CODE_SERVER_PASSWORD}" ]]; then
    CODE_SERVER_PASSWORD="$(generate_random_password)"
  fi
}

store_password_in_repo_secrets() {
  if [[ ! -f "${TASK_HELPERS_FILE}" || ! -f "${PASSWORDS_ENC_ENV_FILE}" || ! -f "${AGE_KEYS_FILE}" ]]; then
    return 0
  fi

  # shellcheck disable=SC1090
  . "${TASK_HELPERS_FILE}"
  encrypted_dotenv_upsert "${PASSWORD_KEY}" "${CODE_SERVER_PASSWORD}" "${PASSWORDS_ENC_ENV_FILE}" "${PASSWORDS_ENC_ENV_FILE_REL}"
}

write_default_config_if_missing() {
  mkdir -p "${CONFIG_DIR}"

  if [[ -f "${CONFIG_FILE}" ]]; then
    msg_ok "Existing config preserved"
    return
  fi

  set_bootstrap_password
  msg_info "Creating starter config"
  cat > "${CONFIG_FILE}" <<EOF
bind-addr: 0.0.0.0:8680
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: false
EOF
  chmod 600 "${CONFIG_FILE}"
  store_password_in_repo_secrets || true
  msg_ok "Created starter config"
}

enable_service() {
  msg_info "Enabling code-server service"
  systemctl enable --now "code-server@${USER}"
  systemctl restart "code-server@${USER}"
  msg_ok "Enabled code-server service"
}

show_summary() {
  local access_ip="${IP_ADDRESS:-127.0.0.1}"

  echo
  echo -e "${GN}${APP} ${VERSION} installed on ${HOSTNAME_SHORT}${CL}"
  echo -e "Local URL:   ${BL}http://127.0.0.1:8680${CL}"
  echo -e "LAN URL:     ${BL}http://${access_ip}:8680${CL}"
  echo -e "Config file: ${BL}${CONFIG_FILE}${CL}"
  if [[ -n "${CODE_SERVER_PASSWORD}" ]]; then
    echo "Bootstrap password was created for first-run access."
    if [[ -f "${PASSWORDS_ENC_ENV_FILE}" ]]; then
      echo "A copy was also written to ${PASSWORDS_ENC_ENV_FILE}."
    fi
  fi
  echo
}

main() {
  clear || true
  header_info
  ensure_not_proxmox_host
  ensure_not_alpine
  confirm_install
  install_dependencies
  install_code_server
  write_default_config_if_missing
  enable_service
  show_summary
}

main "$@"