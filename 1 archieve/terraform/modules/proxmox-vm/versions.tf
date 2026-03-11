# ================================================================
# File: terraform/modules/proxmox-vm/versions.tf
# Purpose:
#   Declare provider requirements for the reusable Proxmox VM module.
# ================================================================

terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}