# ================================================================
# File: terraform/modules/proxmox-lxc/main.tf
# Purpose:
#   Provision an Ubuntu LXC container from a downloaded template.
#
# Notes:
#   - The template file ID comes from proxmox_virtual_environment_download_file.
#   - Ubuntu LXCs are configured as unprivileged with nesting enabled.
# ================================================================

resource "proxmox_virtual_environment_container" "this" {
  description  = var.description
  node_name    = var.node_name
  vm_id        = var.vm_id
  tags         = var.tags
  started      = true
  unprivileged = true

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
    swap      = 512
  }

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }

    user_account {
      keys = [var.vm_ssh_public_key]
    }
  }

  network_interface {
    name    = "veth0"
    bridge  = var.bridge
    vlan_id = var.vlan_id == 0 ? null : var.vlan_id
  }

  disk {
    datastore_id = var.disk_datastore
    size         = var.disk_size_gb
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = "ubuntu"
  }

  features {
    nesting = true
  }
}
