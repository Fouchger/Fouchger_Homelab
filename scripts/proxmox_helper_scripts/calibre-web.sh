#!/usr/bin/env bash
# ================================================================
# File: scripts/proxmox_helper_scripts/calibre-web.sh
# Purpose:
#   Repository-managed wrapper for the upstream Community Scripts
#   Calibre-Web LXC helper.
#
# Notes:
#   - The proxmox_lxc workflow exports var_ctid and var_hostname.
#   - Override any var_* values before invocation if different
#     sizing, storage, or networking is required.
# ================================================================
set -eu

export var_tags="${var_tags:-media}"
export var_cpu="${var_cpu:-2}"
export var_ram="${var_ram:-1024}"
export var_disk="${var_disk:-8}"
export var_os="${var_os:-debian}"
export var_version="${var_version:-13}"
export var_unprivileged="${var_unprivileged:-1}"

bash -lc "
  set -eu
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/calibre-web.sh)
"
