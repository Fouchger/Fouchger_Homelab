# ================================================================
# File: terraform/providers.tf
# Purpose:
#   Configure the Proxmox provider for the homelab stack.
#
# Notes:
#   - Credentials are injected at runtime from repo-managed secret files.
#   - SSH settings are retained because some provider operations use SSH.
# ================================================================

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure_tls

  ssh {
    username    = var.proxmox_ssh_user
    private_key = file(var.proxmox_ssh_private_key_path)
  }
}
