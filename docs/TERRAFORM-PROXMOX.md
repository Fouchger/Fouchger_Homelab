# Terraform Proxmox Integration

## Purpose
This document explains how the Terraform stack is wired into the repo and how it hands off to Ansible.

## Secret flow
The Terraform tasks do not keep credentials in `.tf` or `.tfvars` files.
They source the existing repo-managed files below instead:

- `state/configs/.env`
- `state/secrets/proxmox/proxmox-api-token.env`
- `state/secrets/ssh/id_ed25519_homelab`
- `state/secrets/ssh/id_ed25519_homelab.pub`

## Core flow
1. `task proxmox:templates:bootstrap` downloads cloud artefacts directly on the Proxmox host and builds the reusable VM templates.
2. Terraform clones service VMs from the stable Proxmox template IDs discovered during bootstrap.
3. Terraform provisions service-driven guests from the service catalogue.
4. Terraform emits a structured `ansible_inventory` output.
5. `scripts/render_inventory.py` renders the final inventory YAML for Ansible.

## Required bootstrap order
1. `task init`
2. `task ssh:keys`
3. `task proxmox:env:ensure`
4. `task proxmox:api-user`
5. `task proxmox:templates:bootstrap`
6. Confirm `PROXMOX_NODE_NAME` and the discovered template identifiers were written into `state/configs/.env`
7. `task terraform:init`
8. `task terraform:validate`
9. `task terraform:apply`
10. `task ansible:inventory:render`
11. `task ansible:playbook`

## Current service pattern
The lab environment models guests as services rather than sample VMs and LXCs.
The current default services are:

- `docker01`
- `authentik01`
- `freeipa01`

`utility01` is intentionally disabled by default until an Ubuntu LXC template file ID is supplied.

## Template strategy
The repository treats template lifecycle as a separate concern from day-2 service provisioning.
In this environment, host-side `wget` on Proxmox has proven more reliable than relying on the Proxmox API download path, so the primary workflow now builds templates over SSH with native Proxmox commands and then feeds the resulting IDs back into Terraform through environment-backed maps.

## Optional bootstrap workflow
If you want Terraform to attempt image download and template creation on Proxmox, run:

```bash
task terraform:bootstrap:plan
task terraform:bootstrap:apply
```

Use this path only after confirming:

- the Proxmox node can fetch the image URLs directly
- the API token has the required Proxmox privileges for the `download-url` workflow
- the target datastore supports the relevant content types

## Notes
- The Terraform stack uses the `bpg/proxmox` provider.
- Ubuntu 24.04 remains the default Ubuntu base image for service VMs.
- Rocky Linux 9 remains the preferred FreeIPA server base image.
- Ubuntu 25 is retained in the catalogue but disabled by default to keep the baseline stable.
