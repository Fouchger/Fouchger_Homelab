# ================================================================
# File: terraform/environments/lab/outputs.tf
# Purpose:
#   Expose resolved template identifiers, provisioned guests, and the
#   generated Ansible inventory for downstream automation.
# ================================================================

output "resolved_vm_template_ids" {
  description = "Resolved VM template IDs by image key, including supplied IDs and any Terraform-built templates"
  value       = local.resolved_vm_template_ids
}

output "resolved_lxc_template_file_ids" {
  description = "Resolved LXC template file IDs by image key, including supplied IDs and any Terraform-downloaded template files"
  value       = local.resolved_lxc_template_file_ids
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
  value       = local.inventory_services
}

output "ansible_inventory" {
  description = "Generated inventory structure for downstream Ansible rendering"
  value       = local.ansible_inventory
}
