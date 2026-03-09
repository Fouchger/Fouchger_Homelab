# ================================================================
# File: terraform/locals.tf
# Purpose:
#   Centralise Ubuntu release metadata and sample homelab definitions.
#
# Notes:
#   - Ubuntu 24.04 and 25.10 URLs are current release endpoints.
#   - Ubuntu 26.04 is intentionally disabled until final release media exists.
# ================================================================

locals {
  ubuntu_releases = {
    ubuntu24 = {
      release_label = "24.04"
      codename      = "noble"
      enabled       = true
      vm_image_url  = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      lxc_url       = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64-root.tar.xz"
      vm_file_name  = "ubuntu-24.04-server-cloudimg-amd64.img"
      lxc_file_name = "ubuntu-24.04-server-cloudimg-amd64-root.tar.xz"
      tags          = ["ubuntu", "ubuntu24", "noble"]
    }
    ubuntu25 = {
      release_label = "25.10"
      codename      = "questing"
      enabled       = true
      vm_image_url  = "https://cloud-images.ubuntu.com/releases/server/25.10/release/ubuntu-25.10-server-cloudimg-amd64.img"
      lxc_url       = "https://cloud-images.ubuntu.com/releases/server/25.10/release/ubuntu-25.10-server-cloudimg-amd64-root.tar.xz"
      vm_file_name  = "ubuntu-25.10-server-cloudimg-amd64.img"
      lxc_file_name = "ubuntu-25.10-server-cloudimg-amd64-root.tar.xz"
      tags          = ["ubuntu", "ubuntu25", "questing"]
    }
    ubuntu26 = {
      release_label = "26.04"
      codename      = "future-lts"
      enabled       = var.ubuntu_26_enabled
      vm_image_url  = "https://cloud-images.ubuntu.com/releases/server/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img"
      lxc_url       = "https://cloud-images.ubuntu.com/releases/server/26.04/release/ubuntu-26.04-server-cloudimg-amd64-root.tar.xz"
      vm_file_name  = "ubuntu-26.04-server-cloudimg-amd64.img"
      lxc_file_name = "ubuntu-26.04-server-cloudimg-amd64-root.tar.xz"
      tags          = ["ubuntu", "ubuntu26", "future-lts"]
    }
  }

  enabled_ubuntu_releases = {
    for key, release in local.ubuntu_releases : key => release
    if release.enabled
  }

  sample_vms = {
    docker01 = {
      vm_id        = 24001
      release_key  = "ubuntu24"
      name         = "docker01"
      description  = "Ubuntu 24.04 VM for container workloads"
      cpu_cores    = 4
      memory_mb    = 8192
      disk_size_gb = 80
      bridge       = "vmbr0"
      vlan_id      = 20
      ipv4_address = "192.168.20.41/24"
      ipv4_gateway = "192.168.20.1"
      tags         = ["vm", "docker"]
    }
    test01 = {
      vm_id        = 25001
      release_key  = "ubuntu25"
      name         = "test01"
      description  = "Ubuntu 25.10 validation VM"
      cpu_cores    = 2
      memory_mb    = 4096
      disk_size_gb = 40
      bridge       = "vmbr0"
      vlan_id      = 30
      ipv4_address = "192.168.30.51/24"
      ipv4_gateway = "192.168.30.1"
      tags         = ["vm", "test"]
    }
  }

  sample_lxcs = {
    utility01 = {
      vm_id        = 24101
      release_key  = "ubuntu24"
      name         = "utility01"
      description  = "Ubuntu 24.04 LXC utility host"
      cpu_cores    = 2
      memory_mb    = 2048
      disk_size_gb = 8
      bridge       = "vmbr0"
      vlan_id      = 20
      ipv4_address = "192.168.20.81/24"
      ipv4_gateway = "192.168.20.1"
      tags         = ["lxc", "utility"]
    }
    utility25 = {
      vm_id        = 25101
      release_key  = "ubuntu25"
      name         = "utility25"
      description  = "Ubuntu 25.10 LXC validation host"
      cpu_cores    = 2
      memory_mb    = 2048
      disk_size_gb = 8
      bridge       = "vmbr0"
      vlan_id      = 30
      ipv4_address = "192.168.30.81/24"
      ipv4_gateway = "192.168.30.1"
      tags         = ["lxc", "validation"]
    }
  }
}
