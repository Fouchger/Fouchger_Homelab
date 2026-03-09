# ================================================================
# File: terraform/modules/proxmox-lxc/variables.tf
# Purpose:
#   Define the inputs for the reusable Proxmox LXC module.
# ================================================================

variable "name" {
  description = "Container hostname"
  type        = string
}

variable "description" {
  description = "Container description"
  type        = string
  default     = ""
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_id" {
  description = "Static Proxmox container ID"
  type        = number
}

variable "template_file_id" {
  description = "Ubuntu LXC template file ID"
  type        = string
}

variable "disk_datastore" {
  description = "Datastore for the root disk"
  type        = string
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Dedicated memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Root disk size in GB"
  type        = number
  default     = 8
}

variable "bridge" {
  description = "Proxmox bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "Optional VLAN tag"
  type        = number
  default     = 0
}

variable "ipv4_address" {
  description = "IPv4 address in CIDR format or dhcp"
  type        = string
}

variable "ipv4_gateway" {
  description = "IPv4 gateway"
  type        = string
}

variable "vm_ssh_public_key" {
  description = "SSH public key injected into the container root account"
  type        = string
}

variable "tags" {
  description = "Tags applied to the container"
  type        = list(string)
  default     = []
}