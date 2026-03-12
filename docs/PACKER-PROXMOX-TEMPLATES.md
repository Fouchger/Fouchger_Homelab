# Packer Proxmox Templates

## Purpose
This document describes the curated Packer template workflow integrated into this homelab repository.

## Source and curation approach
The Packer foundation in `packer/` is derived from the upstream `proxmox-packer-templates` project and then trimmed to fit this repository.

What has been kept:
- shared Proxmox builder logic
- Ubuntu, Rocky, Alpine, Talos, OPNsense, and Windows template definitions that fit the lab scope
- required autoinstall, kickstart, unattended, and helper assets
- repo-managed OS template defaults

What has been deliberately left out:
- GitHub Actions CI pipelines
- broader upstream templates that are still outside the current platform scope
- auxiliary test harnesses that are not yet part of the local delivery flow

## Why this fits the project
This pattern aligns well with the repository direction because it separates image creation from service provisioning and gives Terraform a stable template layer to clone from.

It also complements the existing SSH-driven bootstrap method rather than replacing it outright.

## Build prerequisites
Before building templates, ensure the following are in place:

1. `task proxmox:api-user` has been run successfully.
2. `task bootstrap_tasks:packer` has installed Packer locally.
3. `state/configs/.env` contains the discovered Proxmox node details.
4. `state/secrets/proxmox/proxmox-api-token.env` exists locally.

## Local variable rendering
The task `packer:vars:render` generates `packer/local.auto.pkrvars.hcl` from the local bootstrap state.

That file contains host-specific and token-based build values and must remain uncommitted.

## Curated templates
### Linux and appliance guests
- Ubuntu 22.04, default VM ID `9103`
- Ubuntu 24.04, default VM ID `9102`
- Ubuntu 25.04, default VM ID `9104`
- Rocky Linux 9, default VM ID `9101`
- Rocky Linux 10, default VM ID `9105`
- Talos Linux 1.12, default VM ID `9112`
- OPNsense 25.7, default VM ID `9125`
- OPNsense 26.1, default VM ID `9126`
- Alpine Linux 3.21, default VM ID `9131`
- Alpine Linux 3.22, default VM ID `9132`

### Windows guests
- Windows Server 2022, default VM ID `9142`
- Windows Server 2025, default VM ID `9145`
- Windows 11, default VM ID `9111`

## Recommended commands
```bash
task packer:validate
task packer:build:linux-core
```

Build specific guests only when you need them:

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

## Operating model
Use the curated Packer path when you want more repeatable VM templates with explicit installer behaviour.

Use `task proxmox:templates:bootstrap` when you want the lightest possible fallback path and do not need the fuller installer-driven build model.

## Important notes
- Talos and OPNsense are intentionally kept outside the cloud-init-centric Linux path and should be treated as specialised guests.
- Windows template builds depend on the included unattended assets and WinRM communicator settings.
- Ubuntu 25.04 is included as a local extension of the curated catalogue rather than as an original upstream subset file.
