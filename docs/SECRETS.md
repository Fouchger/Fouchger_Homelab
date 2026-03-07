# Secrets Standard

## Purpose
This document describes the day-one homelab secrets standard using Task, age, SOPS, and OpenBao.

## Design principles
- All secrets-related material lives under `state/secrets/`
- File-based secrets use `SOPS + age`
- Runtime and brokered secrets use `OpenBao`
- Tasks are written to be re-runnable without clobbering existing state
- Plaintext is minimised and temporary working files are confined to `state/secrets/.tmp/`

## Directory layout
```text
state/secrets/
  .tmp/
  age/
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
6. Protect and back up `state/secrets/openbao/bootstrap/` and `state/secrets/age/`

## Important notes
- Never commit plaintext tokens, private keys, or unseal material.
- Treat the OpenBao bootstrap directory as highly sensitive.
- For multi-node OpenBao later, extend the SAN entries and transit auto-unseal flow before adding peers.
