# ================================================================
# File: terraform/modules/proxmox-vm/outputs.tf
# Purpose:
#   Expose identifiers from the reusable Proxmox VM module.
# ================================================================

output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}
