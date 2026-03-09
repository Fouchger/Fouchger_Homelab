# ================================================================
# File: terraform/modules/proxmox-lxc/versions.tf
# Purpose:
#   Declare provider requirements for the reusable Proxmox LXC module.
# ================================================================

terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}