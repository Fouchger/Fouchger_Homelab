# ================================================================
# File: terraform/versions.tf
# Purpose:
#   Pin the Terraform and provider versions for the Proxmox homelab stack.
#
# Notes:
#   - The bpg/proxmox provider is the current maintained choice for
#     Proxmox Terraform automation.
#   - Version 0.97.1 was published on 27 February 2026 at the time of review.
# ================================================================

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.98.1"
    }
  }
}
