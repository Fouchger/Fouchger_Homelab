# Fouchger Homelab

## Purpose
This repository provides a repeatable homelab automation pattern built around Task, Proxmox, Packer, Terraform, Ansible, and OpenBao.

## Current automation direction
The stack is standardised around the following delivery flow:

1. Task orchestrates operator workflows.
2. Template bootstrap is handled separately from steady-state service provisioning.
3. Packer now provides the preferred VM template build path for curated Proxmox images.
4. An SSH-driven Proxmox host bootstrap path remains available as a lean fallback for rapid seeding.
5. Terraform provisions Proxmox VMs from stable template identifiers.
6. Terraform outputs are rendered into Ansible inventory.
7. Ansible applies the base operating system configuration and service roles.
8. Service-specific APIs and providers are configured after the platform is online.

## Identity direction
The current identity roadmap is:

- OpenBao for secrets and bootstrap material
- authentik for application SSO
- FreeIPA for Linux identity and policy when required

## Repository bootstrap
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Fouchger/Fouchger_Homelab/refs/heads/branch2/install.sh)"
```

