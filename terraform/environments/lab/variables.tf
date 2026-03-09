# ================================================================
# File: terraform/variables.tf
# Purpose:
#   Define the shared Terraform inputs for Proxmox, Ubuntu templates,
#   VM instances, and LXC instances.
#
# Notes:
#   - Sensitive values are supplied by Task wrappers from repo-managed
#     secret files under state/secrets/.
#   - Ubuntu 26.04 inputs are present for future readiness but disabled
#     by default until release media is confirmed.
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
  description = "Datastore used for Ubuntu cloud images and LXC templates"
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
  description = "SSH public key injected into Ubuntu VMs and LXCs"
  type        = string
}

variable "ubuntu_26_enabled" {
  description = "Enable Ubuntu 26.04 resources after release media has been confirmed"
  type        = bool
  default     = false
}
