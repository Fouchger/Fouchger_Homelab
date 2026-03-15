#!/usr/bin/env bash

# ============================================================
# File:   code_server_install.sh
# Code Server Installer
# Installs code-server via the official installer, pinned to
# version 4.109.5, then enables the user systemd service.
#
# Notes:
# - Intended for Debian/Ubuntu style environments with systemd
# - Refuses to run on a Proxmox host or Alpine
# - Preserves an existing code-server config if present
# - If no config exists, writes a safe starter config
# ============================================================

set -Eeuo pipefail
shopt -s expand_aliases

APP="Coder Code Server"
VERSION="4.109.5"
CONFIG_DIR="${HOME}/.config/code-server"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
HOSTNAME_SHORT="$(hostname)"
IP_ADDRESS="$(hostname -I 2>/dev/null | awk '{print $1}')"

YW='\033[33m'
BL='\033[36m'
RD='\033[01;31m'
GN='\033[1;92m'
CL='\033[m'
BFR='\r\033[K'
HOLD='-'
CM="${GN}✓${CL}"

alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR

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
  trap - ERR
  local reason="${1:-Unknown failure occurred.}"
  local flag="${RD}‼ ERROR ${CL}${EXIT}@${LINE}"
  echo -e "${flag} ${reason}" >&2
  exit "${EXIT}"
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
    echo -e "⚠️  Can't install on a Proxmox host"
    exit 1
  fi
}

ensure_not_alpine() {
  if [[ -e /etc/alpine-release ]]; then
    echo -e "⚠️  Can't install on Alpine"
    exit 1
  fi
}

confirm_install() {
  while true; do
    read -r -p "This will install ${APP} ${VERSION} on ${HOSTNAME_SHORT}. Proceed (y/n)? " yn
    case "${yn}" in
      [Yy]*) break ;;
      [Nn]*) exit 0 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

install_dependencies() {
  msg_info "Installing dependencies"
  apt-get update -qq
  apt-get install -y -qq curl ca-certificates
  msg_ok "Installed dependencies"
}

install_code_server() {
  msg_info "Installing ${APP} v${VERSION}"
  curl -fsSL https://code-server.dev/install.sh | sh -s -- --version "${VERSION}"
  msg_ok "Installed ${APP} v${VERSION}"
}

write_default_config_if_missing() {
  mkdir -p "${CONFIG_DIR}"

  if [[ -f "${CONFIG_FILE}" ]]; then
    msg_ok "Existing config preserved"
    return
  fi

  msg_info "Creating starter config"
  cat > "${CONFIG_FILE}" <<EOF
bind-addr: 0.0.0.0:8680
auth: password
password: Fluffy@1215
cert: false
EOF
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
  echo
  echo "If this is the first install, check the config file for the generated password"
  echo "or update the config before exposing the service beyond your LAN."
  echo
}

main() {
  clear
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
