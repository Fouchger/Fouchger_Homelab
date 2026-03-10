# ================================================================
# File: terraform/environments/lab/main.tf
# Purpose:
#   Compose the homelab Proxmox stack using service-driven guest definitions.
#
# Notes:
#   - Steady-state provisioning clones from existing template IDs by default.
#   - Template bootstrap remains available only when explicitly enabled.
#   - LXC services are skipped until a matching template file ID is provided.
# ================================================================

terraform {
  backend "local" {}
}

resource "proxmox_virtual_environment_download_file" "vm_images" {
  for_each = var.enable_template_bootstrap ? local.enabled_vm_image_catalog : {}

  content_type = "iso"
  datastore_id = var.proxmox_template_datastore
  file_name    = each.value.file_name
  node_name    = var.proxmox_node_name
  url          = each.value.image_url
  overwrite    = false
}

resource "proxmox_virtual_environment_download_file" "ubuntu_lxc_templates" {
  for_each = var.enable_template_bootstrap ? local.enabled_ubuntu_releases : {}

  content_type = "vztmpl"
  datastore_id = var.proxmox_template_datastore
  file_name    = each.value.lxc_file_name
  node_name    = var.proxmox_node_name
  url          = each.value.lxc_url
  overwrite    = false
}

resource "proxmox_virtual_environment_vm" "vm_templates" {
  for_each = var.enable_template_bootstrap ? local.enabled_vm_image_catalog : {}

  name        = "tpl-${each.key}-cloudinit"
  description = "Terraform-managed template for ${each.key}"
  node_name   = var.proxmox_node_name
  vm_id       = 9000 + index(sort(keys(local.enabled_vm_image_catalog)), each.key) + 1
  tags        = concat(each.value.tags, ["template", "cloudinit"])
  template    = true
  started     = false
  machine     = "q35"
  bios        = "ovmf"

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
    floating  = 1024
  }

  efi_disk {
    datastore_id = var.proxmox_vm_datastore
    type         = "4m"
  }

  disk {
    datastore_id = var.proxmox_vm_datastore
    file_id      = proxmox_virtual_environment_download_file.vm_images[each.key].id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = each.value.default_user
      keys     = [var.vm_ssh_public_key]
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
}

module "services_vm" {
  for_each = local.vm_services

  source = "../../modules/proxmox-vm"

  name               = each.value.name
  description        = each.value.description
  node_name          = var.proxmox_node_name
  vm_id              = each.value.vm_id
  clone_source_vm_id = local.resolved_vm_template_ids[each.value.image_key]
  target_datastore   = var.proxmox_vm_datastore
  cpu_cores          = each.value.cpu_cores
  memory_mb          = each.value.memory_mb
  disk_size_gb       = each.value.disk_size_gb
  bridge             = each.value.bridge
  vlan_id            = each.value.vlan_id
  ipv4_address       = each.value.ipv4_address
  ipv4_gateway       = each.value.ipv4_gateway
  dns_servers        = var.default_dns_servers
  vm_ssh_public_key  = var.vm_ssh_public_key
  cloud_init_user    = local.vm_image_catalog[each.value.image_key].default_user
  tags               = concat(local.vm_image_catalog[each.value.image_key].tags, each.value.tags)
}

module "services_lxc" {
  for_each = local.lxc_services

  source = "../../modules/proxmox-lxc"

  name              = each.value.name
  description       = each.value.description
  node_name         = var.proxmox_node_name
  vm_id             = each.value.vm_id
  template_file_id  = local.resolved_lxc_template_file_ids[each.value.image_key]
  disk_datastore    = var.proxmox_vm_datastore
  cpu_cores         = each.value.cpu_cores
  memory_mb         = each.value.memory_mb
  disk_size_gb      = each.value.disk_size_gb
  bridge            = each.value.bridge
  vlan_id           = each.value.vlan_id
  ipv4_address      = each.value.ipv4_address
  ipv4_gateway      = each.value.ipv4_gateway
  vm_ssh_public_key = var.vm_ssh_public_key
  tags              = concat(local.ubuntu_releases[each.value.image_key].tags, each.value.tags)
}
