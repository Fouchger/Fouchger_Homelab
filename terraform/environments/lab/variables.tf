# ================================================================
# File: terraform/environments/lab/variables.tf
# Purpose:
#   Define Terraform inputs for the Proxmox-backed lab environment.
# ================================================================

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, for example https://pve01.lab.local:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Full Proxmox API token in user@realm!token=value format"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure_tls" {
  description = "Allow insecure TLS for lab environments"
  type        = bool
  default     = true
}

variable "proxmox_node_name" {
  description = "Default Proxmox node used for downloads and guest placement"
  type        = string
}

variable "proxmox_template_datastore" {
  description = "Datastore used for cloud images and LXC templates"
  type        = string
  default     = "local"
}

variable "proxmox_vm_datastore" {
  description = "Datastore used for VM and container disks"
  type        = string
  default     = "local-lvm"
}

variable "proxmox_snippets_datastore" {
  description = "Datastore used for snippets and cloud-init user-data files"
  type        = string
  default     = "local"
}

variable "proxmox_ssh_user" {
  description = "SSH user for Proxmox provider operations that require SSH"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_private_key_path" {
  description = "Path to the repo-managed SSH private key"
  type        = string
}

variable "vm_ssh_public_key" {
  description = "SSH public key injected into VMs and LXCs"
  type        = string
}

variable "default_dns_servers" {
  description = "Default DNS servers injected into cloud-init for VMs"
  type        = list(string)
  default     = ["1.1.1.1", "9.9.9.9"]
}
