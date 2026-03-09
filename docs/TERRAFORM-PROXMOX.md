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
1. Terraform downloads cloud images and LXC templates.
2. Terraform builds template VMs where needed.
3. Terraform provisions service-driven guests from the service catalogue.
4. Terraform emits a structured `ansible_inventory` output.
5. `scripts/render_inventory.py` renders the final inventory YAML for Ansible.

## Required bootstrap order
1. `task init`
2. `task ssh:keys`
3. `task proxmox:env:ensure`
4. `task proxmox:api-user`
5. `task terraform:init`
6. `task terraform:validate`
7. `task terraform:apply`
8. `task ansible:inventory:render`
9. `task ansible:playbook`

## Current service pattern
The lab environment now models guests as services rather than sample VMs and LXCs.
The current default services are:

- `docker01`
- `authentik01`
- `freeipa01`
- `utility01`

## Notes
- The Terraform stack uses the `bpg/proxmox` provider.
- Ubuntu is used for general-purpose service VMs and LXC templates.
- Rocky Linux 9 is included for the FreeIPA server VM because a RHEL-compatible platform is a better fit for FreeIPA server deployment. FreeIPA provides supported Ansible roles for server installation and management. citeturn0search1turn0search10
- authentik should be configured on a dedicated Ubuntu VM and then managed further through provider-based configuration once the service is online. citeturn0search0turn0search9
