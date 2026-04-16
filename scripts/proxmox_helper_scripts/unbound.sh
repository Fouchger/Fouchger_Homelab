#!/usr/bin/env bash
# ================================================================
# File: scripts/proxmox_helper_scripts/unbound.sh
# Purpose:
#   Repository-managed wrapper for the upstream Community Scripts
#   Unbound LXC helper.
#
# Notes:
#   - The proxmox_lxc workflow exports var_ctid and var_hostname.
#   - Override any var_* values before invocation if different
#     sizing, storage, or networking is required.
# ================================================================
set -eu

export var_tags="${var_tags:-dns}"
export var_cpu="${var_cpu:-1}"
export var_ram="${var_ram:-512}"
export var_disk="${var_disk:-4}"
export var_os="${var_os:-debian}"
export var_version="${var_version:-13}"
export var_unprivileged="${var_unprivileged:-1}"

bash -lc "
  set -eu
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/unbound.sh)
"
