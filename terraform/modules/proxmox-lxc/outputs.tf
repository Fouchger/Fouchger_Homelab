# ================================================================
# File: terraform/modules/proxmox-lxc/outputs.tf
# Purpose:
#   Expose identifiers from the reusable Proxmox LXC module.
# ================================================================

output "container_id" {
  description = "Proxmox container ID"
  value       = proxmox_virtual_environment_container.this.vm_id
}
