# ================================================================
# File: terraform/environments/lab/locals.tf
# Purpose:
#   Define operating system catalog data and service-driven guest metadata.
#
# Notes:
#   - Services are the primary source of truth for guest creation.
#   - Identity hosts are modelled explicitly for authentik and FreeIPA.
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
      default_user  = "ubuntu"
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
      default_user  = "ubuntu"
      tags          = ["ubuntu", "ubuntu25", "questing"]
    }
  }

  rocky_releases = {
    rocky9 = {
      release_label = "9"
      codename      = "blue-onyx"
      enabled       = true
      vm_image_url  = "https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
      vm_file_name  = "rocky-9-genericcloud-base-amd64.qcow2"
      default_user  = "rocky"
      tags          = ["rocky", "rocky9", "rhel-compatible"]
    }
  }

  vm_image_catalog = merge(
    {
      for key, release in local.ubuntu_releases : key => {
        enabled      = release.enabled
        file_name    = release.vm_file_name
        image_url    = release.vm_image_url
        default_user = release.default_user
        tags         = release.tags
      }
    },
    {
      for key, release in local.rocky_releases : key => {
        enabled      = release.enabled
        file_name    = release.vm_file_name
        image_url    = release.vm_image_url
        default_user = release.default_user
        tags         = release.tags
      }
    }
  )

  enabled_vm_image_catalog = {
    for key, image in local.vm_image_catalog : key => image
    if image.enabled
  }

  enabled_ubuntu_releases = {
    for key, release in local.ubuntu_releases : key => release
    if release.enabled
  }

  services = {
    docker01 = {
      guest_type     = "vm"
      image_key      = "ubuntu24"
      vm_id          = 24001
      name           = "docker01"
      description    = "Ubuntu 24.04 VM for container workloads"
      cpu_cores      = 4
      memory_mb      = 8192
      disk_size_gb   = 80
      bridge         = "vmbr0"
      vlan_id        = 20
      ipv4_address   = "192.168.20.41/24"
      ipv4_gateway   = "192.168.20.1"
      ansible_groups = ["linux", "docker_hosts"]
      tags           = ["vm", "docker"]
    }
    authentik01 = {
      guest_type     = "vm"
      image_key      = "ubuntu24"
      vm_id          = 24021
      name           = "authentik01"
      description    = "Dedicated Ubuntu VM for authentik application SSO"
      cpu_cores      = 2
      memory_mb      = 4096
      disk_size_gb   = 40
      bridge         = "vmbr0"
      vlan_id        = 20
      ipv4_address   = "192.168.20.61/24"
      ipv4_gateway   = "192.168.20.1"
      ansible_groups = ["linux", "identity", "identity_authentik", "docker_hosts"]
      tags           = ["vm", "identity", "authentik"]
    }
    freeipa01 = {
      guest_type     = "vm"
      image_key      = "rocky9"
      vm_id          = 24031
      name           = "freeipa01"
      description    = "Dedicated Rocky Linux VM for FreeIPA"
      cpu_cores      = 2
      memory_mb      = 4096
      disk_size_gb   = 40
      bridge         = "vmbr0"
      vlan_id        = 20
      ipv4_address   = "192.168.20.71/24"
      ipv4_gateway   = "192.168.20.1"
      ansible_groups = ["linux", "identity", "identity_freeipa"]
      tags           = ["vm", "identity", "freeipa"]
    }
    utility01 = {
      guest_type     = "lxc"
      image_key      = "ubuntu24"
      vm_id          = 24101
      name           = "utility01"
      description    = "Ubuntu 24.04 LXC utility host"
      cpu_cores      = 2
      memory_mb      = 2048
      disk_size_gb   = 8
      bridge         = "vmbr0"
      vlan_id        = 20
      ipv4_address   = "192.168.20.81/24"
      ipv4_gateway   = "192.168.20.1"
      ansible_groups = ["linux", "utility_hosts"]
      tags           = ["lxc", "utility"]
    }
  }

  vm_services = {
    for key, service in local.services : key => service
    if service.guest_type == "vm" && contains(keys(local.enabled_vm_image_catalog), service.image_key)
  }

  lxc_services = {
    for key, service in local.services : key => service
    if service.guest_type == "lxc" && contains(keys(local.enabled_ubuntu_releases), service.image_key)
  }

  ansible_inventory = {
    all = {
      children = merge(
        {
          for group in distinct(flatten([
            for _, service in local.services : service.ansible_groups
          ])) : group => {
            hosts = {
              for service_key, service in local.services :
              service.name => {
                ansible_host = split("/", service.ipv4_address)[0]
                ansible_user = local.vm_image_catalog[service.image_key].default_user
                homelab_role = try(service.tags[1], service.tags[0])
                proxmox_vm_id = service.vm_id
                proxmox_guest_type = service.guest_type
              }
              if contains(service.ansible_groups, group)
            }
          }
        }
      )
    }
  }
}
