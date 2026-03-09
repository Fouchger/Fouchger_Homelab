# Secrets Standard

## Purpose
This document describes the homelab secrets standard using Task, age, SOPS, OpenBao, Terraform, and Ansible.

## Design principles
- All secrets-related material lives under `state/secrets/`
- File-based secrets use `SOPS + age` where bootstrap is available
- Runtime and brokered secrets use `OpenBao`
- SSH identities used by automation are repo-managed under `state/secrets/ssh/`
- Service-specific local credentials live under service folders inside `state/secrets/`
- Tasks are written to be re-runnable without clobbering existing state
- Plaintext is minimised and temporary working files are confined to `state/secrets/.tmp/`

## Directory layout
```text
state/
  ansible/
    inventory/
  secrets/
    .tmp/
    age/
    ssh/
    proxmox/
    authentik/
    freeipa/
    sops/
    openbao/
      bootstrap/
      runtime/
      policies/
      rendered/
      tls/
      transit/
```

## Terraform and Ansible integration notes
- Terraform sources `state/secrets/proxmox/proxmox-api-token.env` directly.
- Terraform also uses the repo-managed SSH key under `state/secrets/ssh/`.
- Generated Ansible inventory is written to `state/ansible/inventory/`.
- Service bootstrap secrets for authentik and FreeIPA should be sourced from OpenBao before Ansible deployment.

## Important notes
- Never commit plaintext tokens, private keys, or unseal material.
- Treat the OpenBao bootstrap directory as highly sensitive.
- Treat `state/secrets/ssh/`, `state/secrets/proxmox/`, `state/secrets/authentik/`, and `state/secrets/freeipa/` as operator-only material.
