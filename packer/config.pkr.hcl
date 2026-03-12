// ================================================================
// File: packer/config.pkr.hcl
// Purpose:
//   Pin the Packer Proxmox plugin used for homelab template builds.
//
// Notes:
//   - Derived from the upstream proxmox-packer-templates project and
//     curated for this repository.
//   - Keep plugin versions deliberate to avoid silent builder drift.
// ================================================================

packer {
  required_plugins {
    proxmox = {
      # renovate: githubReleaseVar repo=hashicorp/packer-plugin-proxmox
      version = "v1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}