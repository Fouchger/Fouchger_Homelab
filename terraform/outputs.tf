# ================================================================
# File: terraform/outputs.tf
# Purpose:
#   Expose the downloaded Ubuntu file IDs and provisioned guest details.
# ================================================================

output "ubuntu_vm_image_file_ids" {
  description = "Downloaded Ubuntu VM cloud image file IDs by release"
  value = {
    for key, file in proxmox_virtual_environment_download_file.ubuntu_vm_images :
    key => file.id
  }
}

output "ubuntu_lxc_template_file_ids" {
  description = "Downloaded Ubuntu LXC template file IDs by release"
  value = {
    for key, file in proxmox_virtual_environment_download_file.ubuntu_lxc_templates :
    key => file.id
  }
}

output "vm_ids" {
  description = "Provisioned VM identifiers by name"
  value = {
    for key, module in module.sample_vms :
    key => module.vm_id
  }
}

output "container_ids" {
  description = "Provisioned LXC identifiers by name"
  value = {
    for key, module in module.sample_lxcs :
    key => module.container_id
  }
}
