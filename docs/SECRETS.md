# Secrets Standard

## Purpose
This document describes the day-one homelab secrets standard using Task, age, SOPS, OpenBao, and repo-managed SSH material.

## Design principles
- All secrets-related material lives under `state/secrets/`
- File-based secrets use `SOPS + age` where bootstrap is available
- Runtime and brokered secrets use `OpenBao`
- SSH identities used by automation are repo-managed under `state/secrets/ssh/`
- Service-specific local credentials, such as Proxmox API tokens, live under service folders inside `state/secrets/`
- Tasks are written to be re-runnable without clobbering existing state
- Plaintext is minimised and temporary working files are confined to `state/secrets/.tmp/`

## Directory layout
```text
state/secrets/
  .tmp/
  age/
  ssh/
  proxmox/
  sops/
  openbao/
    bootstrap/
    runtime/
    policies/
    rendered/
    tls/
    transit/
```

## Recommended rollout
1. Run `task init`
2. Run `task tools:install`
3. Run `task sops:bootstrap`
4. Review `OPENBAO_HOST`, `OPENBAO_DNS_ALT_NAMES`, and `OPENBAO_IP_ALT_NAMES`
5. Run `task openbao:bootstrap:standalone`
6. Run `task proxmox:api-user` when you are ready to bootstrap the Proxmox automation identity
7. Protect and back up `state/secrets/openbao/bootstrap/`, `state/secrets/age/`, `state/secrets/ssh/`, and any local Proxmox token material

## Proxmox-specific notes
- Proxmox operator settings are kept in `state/configs/.env`
- The local sourceable token file is written to `state/secrets/proxmox/proxmox-api-token.env` with mode `0600`
- When SOPS bootstrap is already present, an encrypted token snapshot is also written to `state/secrets/proxmox/proxmox-api-token.enc.json`
- The Proxmox bootstrap task avoids rotating the remote token when the local token file already exists, which reduces accidental credential churn

## Important notes
- Never commit plaintext tokens, private keys, or unseal material
- Treat the OpenBao bootstrap directory as highly sensitive
- Treat `state/secrets/ssh/` and `state/secrets/proxmox/` as operator-only material
- For multi-node OpenBao later, extend the SAN entries and transit auto-unseal flow before adding peers

## Terraform integration notes
- Terraform sources `state/secrets/proxmox/proxmox-api-token.env` directly.
- Terraform also uses the repo-managed SSH key under `state/secrets/ssh/`.
- Optional Proxmox environment overrides such as `PROXMOX_NODE_NAME` and datastore settings can live in `state/configs/.env`.
