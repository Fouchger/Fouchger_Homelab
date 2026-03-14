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

## Core workflows
```bash
task proxmox:api-user
task packer:validate
task packer:build:linux-core
task proxmox:templates:bootstrap
```

## Template build options
### Preferred curated path
Use the curated Packer workflow when you want reproducible Proxmox VM templates for the following guests:

- Ubuntu 22.04
- Ubuntu 24.04
- Ubuntu 25.04
- Rocky Linux 9
- Rocky Linux 10
- Talos Linux 1.12
- OPNsense 25.7
- OPNsense 26.1
- Alpine Linux 3.21
- Alpine Linux 3.22
- Windows Server 2022
- Windows Server 2025
- Windows 11

```bash
task packer:validate
task packer:build:linux-core
```

Build specific templates as required:

```bash
task packer:build:ubuntu22
task packer:build:ubuntu24
task packer:build:ubuntu25
task packer:build:rocky9
task packer:build:rocky10
task packer:build:talos112
task packer:build:opnsense257
task packer:build:opnsense261
task packer:build:alpine321
task packer:build:alpine322
task packer:build:windows-server2022
task packer:build:windows-server2025
task packer:build:windows11
```

### Fast fallback path
Use the SSH-driven Proxmox bootstrap path only when you want the lightest possible template seeding from the Proxmox host itself:

```bash
task proxmox:templates:bootstrap
```

## Default service scope
The default steady-state service stack is intended to provision:

- `docker01`
- `authentik01`
- `freeipa01`

`utility01` remains available, but is disabled until an Ubuntu LXC template file ID is supplied.

## Documentation
- `docs/PACKER-PROXMOX-TEMPLATES.md`
- `docs/AUTOMATION-ARCHITECTURE.md`
- `docs/IDENTITY-SERVICES.md`
