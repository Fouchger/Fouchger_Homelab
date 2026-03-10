# Fouchger Homelab

## Purpose
This repository provides a repeatable homelab automation pattern built around Task, Terraform, Proxmox, Ansible, and OpenBao.

## Current automation direction
The stack is standardised around the following delivery flow:

1. Task orchestrates operator workflows.
2. Template bootstrap is handled separately from steady-state service provisioning.
3. Proxmox template download now uses native host-side tooling over SSH so it does not depend on the Proxmox API download path.
4. Terraform provisions Proxmox VMs from stable template identifiers.
5. Terraform outputs are rendered into Ansible inventory.
6. Ansible applies the base operating system configuration and service roles.
7. Service-specific APIs and providers are configured after the platform is online.

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
task proxmox:templates:bootstrap
task terraform:plan
task terraform:apply
task ansible:inventory:render
task ansible:ping
task service:authentik:deploy
task service:freeipa:deploy
```

## Optional template bootstrap workflow
Use the bootstrap workflow only when you deliberately want Terraform to attempt Proxmox-side image downloads and template creation:

```bash
task terraform:bootstrap:plan
task terraform:bootstrap:apply
```

## Default service scope
The default steady-state service stack provisions:

- `docker01`
- `authentik01`
- `freeipa01`

`utility01` remains available, but is disabled until an Ubuntu LXC template file ID is supplied.

## Documentation
- `docs/TERRAFORM-PROXMOX.md`
- `docs/AUTOMATION-ARCHITECTURE.md`
- `docs/ANSIBLE.md`
- `docs/IDENTITY-SERVICES.md`
