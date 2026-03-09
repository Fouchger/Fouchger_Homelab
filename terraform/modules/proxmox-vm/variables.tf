# ================================================================
# File: terraform/modules/proxmox-vm/variables.tf
# Purpose:
#   Define the inputs for the reusable Proxmox VM module.
# ================================================================

variable "name" { description = "VM name" type = string }
variable "description" { description = "VM description" type = string default = "" }
variable "node_name" { description = "Proxmox node name" type = string }
variable "vm_id" { description = "Static Proxmox VM ID" type = number }
variable "clone_source_vm_id" { description = "Template VM ID used for cloning" type = number }
variable "target_datastore" { description = "Datastore for cloned VM disks" type = string }
variable "cpu_cores" { description = "Number of CPU cores" type = number default = 2 }
variable "memory_mb" { description = "Dedicated memory in MB" type = number default = 4096 }
variable "disk_size_gb" { description = "Boot disk size in GB" type = number default = 40 }
variable "bridge" { description = "Proxmox bridge" type = string default = "vmbr0" }
variable "vlan_id" { description = "Optional VLAN tag" type = number default = 0 }
variable "ipv4_address" { description = "IPv4 address in CIDR format or dhcp" type = string }
variable "ipv4_gateway" { description = "IPv4 gateway" type = string }
variable "dns_servers" { description = "DNS servers for cloud-init" type = list(string) default = ["1.1.1.1", "9.9.9.9"] }
variable "vm_ssh_public_key" { description = "SSH public key injected by cloud-init" type = string }
variable "tags" { description = "Tags applied to the VM" type = list(string) default = [] }
