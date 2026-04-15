#!/usr/bin/env bash
# ================================================================
# File: scripts/proxmox_workflows/generic-vm-discovery.sh
# Purpose:
#   Execute a server-specific VM helper script on the Proxmox host,
#   then discover the resulting VM metadata and persist a simple
#   dotenv-style result file for the local Task workflow.
#
# Notes:
#   - This script is uploaded to, and runs on, the Proxmox host.
#   - The helper script named by HELPER_SCRIPT_NAME is expected to
#     create or reconcile the target VM.
#   - Discovery uses qm config output and attempts to read the guest
#     agent network interfaces when available.
# ================================================================
set -eu

remote_tmp_dir="${REMOTE_TMP_DIR:?REMOTE_TMP_DIR is required}"
helper_script_name="${HELPER_SCRIPT_NAME:?HELPER_SCRIPT_NAME is required}"
result_file="${RESULT_FILE:-vm-discovery.env}"
vm_default_id="${VM_DEFAULT_ID:?VM_DEFAULT_ID is required}"
vm_default_hostname="${VM_DEFAULT_HOSTNAME:?VM_DEFAULT_HOSTNAME is required}"
vm_primary_nic="${VM_PRIMARY_NIC:-net0}"

helper_script_path="${remote_tmp_dir}/${helper_script_name}"
result_path="${remote_tmp_dir}/${result_file}"

command -v qm >/dev/null 2>&1 || {
  echo 'qm is not available on the remote Proxmox host.' >&2
  exit 1
}

[ -f "$helper_script_path" ] || {
  echo "VM helper script not found on remote host: $helper_script_path" >&2
  exit 1
}

chmod 700 "$helper_script_path"
bash "$helper_script_path"

vm_created='0'
if qm status "$vm_default_id" >/dev/null 2>&1; then
  vm_created='1'
fi

vmid="$vm_default_id"
hostname="$vm_default_hostname"
qm_config="$(qm config "$vmid")"

configured_name="$(printf '%s\n' "$qm_config" | sed -n 's/^name: //p' | head -n 1)"
if [ -n "$configured_name" ]; then
  hostname="$configured_name"
fi

nic_config="$(printf '%s\n' "$qm_config" | sed -n "s/^${vm_primary_nic}: //p" | head -n 1)"
mac_address=''
bridge_name=''

if [ -n "$nic_config" ]; then
  mac_address="$(printf '%s\n' "$nic_config" | sed -n 's/^virtio=\([^,]*\).*/\1/p' | head -n 1)"
  if [ -z "$mac_address" ]; then
    mac_address="$(printf '%s\n' "$nic_config" | sed -n 's/^e1000=\([^,]*\).*/\1/p' | head -n 1)"
  fi
  if [ -z "$mac_address" ]; then
    mac_address="$(printf '%s\n' "$nic_config" | sed -n 's/^rtl8139=\([^,]*\).*/\1/p' | head -n 1)"
  fi
  bridge_name="$(printf '%s\n' "$nic_config" | sed -n 's/.*bridge=\([^,]*\).*/\1/p' | head -n 1)"
fi

ip_address=''
if qm guest cmd "$vmid" network-get-interfaces >/dev/null 2>&1; then
  ip_address="$(qm guest cmd "$vmid" network-get-interfaces 2>/dev/null | jq -r '
    .[]
    | select(.name != "lo")
    | .["ip-addresses"][]?
    | select(.["ip-address-type"] == "ipv4")
    | .["ip-address"]
  ' | grep -v '^127\.' | head -n 1 || true)"
fi

cat > "$result_path" <<EOF
RESULT_CREATED=${vm_created}
RESULT_VMID=${vmid}
RESULT_HOSTNAME=${hostname}
RESULT_MAC=${mac_address}
RESULT_BRIDGE=${bridge_name}
RESULT_IP=${ip_address}
RESULT_PRIMARY_NIC=${vm_primary_nic}
EOF

cat "$result_path"