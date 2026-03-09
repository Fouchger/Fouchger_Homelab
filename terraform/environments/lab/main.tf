# ================================================================
# File: terraform/environments/lab/main.tf
# Purpose:
#   Compose the homelab Proxmox stack using the shared modules.
#
# Notes:
#   - Ubuntu VM cloud images and Ubuntu LXC templates are downloaded first.
#   - VM templates are created in Proxmox and then cloned into sample VMs.
#   - Ubuntu 26.04 remains opt-in until release media is confirmed.
# ================================================================

terraform {
  backend "local" {}
}

locals {
  ubuntu_release_map = local.enabled_ubuntu_releases
}

resource "proxmox_virtual_environment_download_file" "ubuntu_vm_images" {
  for_each = local.ubuntu_release_map

  content_type = "iso"
  datastore_id = var.proxmox_template_datastore
  file_name    = each.value.vm_file_name
  node_name    = var.proxmox_node_name
  url          = each.value.vm_image_url
  overwrite    = false
}

resource "proxmox_virtual_environment_download_file" "ubuntu_lxc_templates" {
  for_each = local.ubuntu_release_map

  content_type = "vztmpl"
  datastore_id = var.proxmox_template_datastore
  file_name    = each.value.lxc_file_name
  node_name    = var.proxmox_node_name
  url          = each.value.lxc_url
  overwrite    = false
}

resource "proxmox_virtual_environment_vm" "ubuntu_templates" {
  for_each = local.ubuntu_release_map

  name        = "tpl-${each.value.codename}-cloudinit"
  description = "Terraform-managed Ubuntu ${each.value.release_label} template"
  node_name   = var.proxmox_node_name
  vm_id       = 9000 + index(keys(local.ubuntu_release_map), each.key) + 1
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
    file_id      = proxmox_virtual_environment_download_file.ubuntu_vm_images[each.key].id
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
      username = "ubuntu"
      keys     = [var.vm_ssh_public_key]
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
}

module "sample_vms" {
  for_each = {
    for key, vm in local.sample_vms : key => vm
    if contains(keys(local.ubuntu_release_map), vm.release_key)
  }

  source = "../../modules/proxmox-vm"

  name               = each.value.name
  description        = each.value.description
  node_name          = var.proxmox_node_name
  vm_id              = each.value.vm_id
  clone_source_vm_id = proxmox_virtual_environment_vm.ubuntu_templates[each.value.release_key].vm_id
  target_datastore   = var.proxmox_vm_datastore
  cpu_cores          = each.value.cpu_cores
  memory_mb          = each.value.memory_mb
  disk_size_gb       = each.value.disk_size_gb
  bridge             = each.value.bridge
  vlan_id            = each.value.vlan_id
  ipv4_address       = each.value.ipv4_address
  ipv4_gateway       = each.value.ipv4_gateway
  vm_ssh_public_key  = var.vm_ssh_public_key
  tags               = concat(local.ubuntu_release_map[each.value.release_key].tags, each.value.tags)

  depends_on = [proxmox_virtual_environment_vm.ubuntu_templates]
}

module "sample_lxcs" {
  for_each = {
    for key, lxc in local.sample_lxcs : key => lxc
    if contains(keys(local.ubuntu_release_map), lxc.release_key)
  }

  source = "../../modules/proxmox-lxc"

  name              = each.value.name
  description       = each.value.description
  node_name         = var.proxmox_node_name
  vm_id             = each.value.vm_id
  template_file_id  = proxmox_virtual_environment_download_file.ubuntu_lxc_templates[each.value.release_key].id
  disk_datastore    = var.proxmox_vm_datastore
  cpu_cores         = each.value.cpu_cores
  memory_mb         = each.value.memory_mb
  disk_size_gb      = each.value.disk_size_gb
  bridge            = each.value.bridge
  vlan_id           = each.value.vlan_id
  ipv4_address      = each.value.ipv4_address
  ipv4_gateway      = each.value.ipv4_gateway
  vm_ssh_public_key = var.vm_ssh_public_key
  tags              = concat(local.ubuntu_release_map[each.value.release_key].tags, each.value.tags)

  depends_on = [proxmox_virtual_environment_download_file.ubuntu_lxc_templates]
}
