# ================================================================
# File: terraform/environments/lab/outputs.tf
# Purpose:
#   Expose downloaded image IDs, provisioned guests, and Ansible inventory.
# ================================================================

output "vm_image_file_ids" {
  description = "Downloaded VM image file IDs by image key"
  value = {
    for key, file in proxmox_virtual_environment_download_file.vm_images :
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
  description = "Provisioned VM identifiers by service name"
  value = {
    for key, module in module.services_vm :
    key => module.vm_id
  }
}

output "container_ids" {
  description = "Provisioned LXC identifiers by service name"
  value = {
    for key, module in module.services_lxc :
    key => module.container_id
  }
}

output "service_catalog" {
  description = "Resolved service metadata used to provision guests"
  value       = local.services
}

output "ansible_inventory" {
  description = "Generated inventory structure for downstream Ansible rendering"
  value       = local.ansible_inventory
}
