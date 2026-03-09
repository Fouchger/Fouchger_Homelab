# ================================================================
# File: terraform/modules/proxmox-vm/main.tf
# Purpose:
#   Provision a Proxmox VM by cloning a Terraform-managed template VM.
#
# Notes:
#   - The template is expected to contain qemu-guest-agent and cloud-init.
#   - The cloud-init username is parameterised to support Ubuntu and Rocky.
# ================================================================

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  node_name   = var.node_name
  vm_id       = var.vm_id
  tags        = var.tags
  started     = true

  clone {
    vm_id = var.clone_source_vm_id
    full  = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory_mb
    floating  = 1024
  }

  agent {
    enabled = true
  }

  initialization {
    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }

    user_account {
      username = var.cloud_init_user
      keys     = [var.vm_ssh_public_key]
    }
  }

  network_device {
    bridge  = var.bridge
    model   = "virtio"
    vlan_id = var.vlan_id == 0 ? null : var.vlan_id
  }

  disk {
    datastore_id = var.target_datastore
    interface    = "scsi0"
    size         = var.disk_size_gb
    discard      = "on"
    iothread     = true
    ssd          = true
  }
}
