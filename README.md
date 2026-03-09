# Fouchger Homelab

## Purpose
This repository provides a repeatable homelab automation pattern built around Task, Terraform, Proxmox, Ansible, and OpenBao.

## Current automation direction
The stack is being standardised around the following delivery flow:

1. Task orchestrates operator workflows.
2. Terraform provisions Proxmox VMs and LXCs.
3. Terraform outputs are rendered into Ansible inventory.
4. Ansible applies the base operating system configuration and service roles.
5. Service-specific APIs and providers are configured after the platform is online.

## Identity direction
The current identity roadmap is:

- OpenBao for secrets and bootstrap material
- authentik for application SSO
- FreeIPA for Linux identity and policy when required

## Repository bootstrap
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Fouchger/Fouchger_Homelab/refs/heads/branch1/install.sh)"
```

## Core workflows
```bash
task terraform:plan
task terraform:apply
task ansible:inventory:render
task ansible:ping
task service:authentik:deploy
task service:freeipa:deploy
```

## Documentation
- `docs/TERRAFORM-PROXMOX.md`
- `docs/AUTOMATION-ARCHITECTURE.md`
- `docs/ANSIBLE.md`
- `docs/IDENTITY-SERVICES.md`

## Images
- [Linux Containers](https://images.linuxcontainers.org/images/)
- [Proxmox LXC](http://download.proxmox.com/images/system/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
