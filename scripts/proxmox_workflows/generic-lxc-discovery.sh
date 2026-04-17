#!/usr/bin/env bash
# ================================================================
# File: scripts/proxmox_workflows/generic-lxc-discovery.sh
# Purpose:
#   Execute a server-specific LXC helper script on the Proxmox host,
#   then discover the resulting container metadata and persist a
#   simple dotenv-style result file for the local Task workflow.
#
# Notes:
#   - This script is uploaded to, and runs on, the Proxmox host.
#   - The helper script named by HELPER_SCRIPT_NAME is expected to
#     create the target LXC container using the Community Scripts
#     build.func workflow.
#   - Strict recreate mode is enforced. If the CTID already exists,
#     the existing container is stopped and destroyed before the
#     helper script is executed.
#   - Discovery uses pct config output and then attempts to read the
#     guest IPv4 address from inside the running container.
# ================================================================
set -eu

remote_tmp_dir="${REMOTE_TMP_DIR:?REMOTE_TMP_DIR is required}"
helper_script_name="${HELPER_SCRIPT_NAME:?HELPER_SCRIPT_NAME is required}"
result_file="${RESULT_FILE:-lxc-discovery.env}"
lxc_default_id="${LXC_DEFAULT_ID:?LXC_DEFAULT_ID is required}"
lxc_default_hostname="${LXC_DEFAULT_HOSTNAME:?LXC_DEFAULT_HOSTNAME is required}"
lxc_primary_nic="${LXC_PRIMARY_NIC:-net0}"

helper_script_path="${remote_tmp_dir}/${helper_script_name}"
result_path="${remote_tmp_dir}/${result_file}"

command -v pct >/dev/null 2>&1 || {
  echo 'pct is not available on the remote Proxmox host.' >&2
  exit 1
}

[ -f "$helper_script_path" ] || {
  echo "LXC helper script not found on remote host: $helper_script_path" >&2
  exit 1
}

strict_recreated='0'
if pct status "$lxc_default_id" >/dev/null 2>&1; then
  strict_recreated='1'
  pct stop "$lxc_default_id" --timeout 30 >/dev/null 2>&1 || true
  pct destroy "$lxc_default_id" --force 1 >/dev/null 2>&1 || true
fi

chmod 700 "$helper_script_path"
export var_ctid="$lxc_default_id"
export var_hostname="$lxc_default_hostname"
bash "$helper_script_path"

pct status "$lxc_default_id" >/dev/null 2>&1 || {
  echo "Expected LXC container $lxc_default_id was not found after helper execution." >&2
  exit 1
}

ct_created='1'
ctid="$lxc_default_id"
hostname="$lxc_default_hostname"
pct_config="$(pct config "$ctid")"

configured_hostname="$(printf '%s\n' "$pct_config" | sed -n 's/^hostname: //p' | head -n 1)"
if [ -n "$configured_hostname" ]; then
  hostname="$configured_hostname"
fi

nic_config="$(printf '%s\n' "$pct_config" | sed -n "s/^${lxc_primary_nic}: //p" | head -n 1)"
mac_address=''
bridge_name=''

if [ -n "$nic_config" ]; then
  mac_address="$(printf '%s\n' "$nic_config" | sed -n 's/.*hwaddr=\([^,]*\).*/\1/p' | head -n 1)"
  bridge_name="$(printf '%s\n' "$nic_config" | sed -n 's/.*bridge=\([^,]*\).*/\1/p' | head -n 1)"
fi

ip_address=''
if pct status "$ctid" 2>/dev/null | grep -q 'running'; then
  ip_address="$(pct exec "$ctid" -- sh -lc "hostname -I 2>/dev/null | awk '{print \\\$1}'" 2>/dev/null | tr -d '\r' | grep -v '^127\.' | head -n 1 || true)"
fi

cat > "$result_path" <<EOF2
RESULT_CREATED=${ct_created}
RESULT_RECREATED=${strict_recreated}
RESULT_CTID=${ctid}
RESULT_HOSTNAME=${hostname}
RESULT_MAC=${mac_address}
RESULT_BRIDGE=${bridge_name}
RESULT_IP=${ip_address}
RESULT_PRIMARY_NIC=${lxc_primary_nic}
EOF2

cat "$result_path"
