# Ansible Layout

## Purpose
This document explains the Ansible structure added to the repository.

## Directory structure
```text
ansible/
  ansible.cfg
  collections/
    requirements.yml
  inventories/
    lab/
      hosts.yml
      group_vars/
        all.yml
  playbooks/
    site.yml
    identity.yml
  roles/
    base_linux/
    container_runtime/
    authentik/
    freeipa_server/
```

## Operating model
- `base_linux` prepares common Linux systems.
- `container_runtime` installs Docker Engine and Compose prerequisites.
- `authentik` deploys authentik with Docker Compose.
- `freeipa_server` installs FreeIPA using the upstream `freeipa.ansible_freeipa` collection.

## Inventory generation
The generated inventory file is written to:

```text
state/ansible/inventory/lab/hosts.yml
```

It is rendered from Terraform outputs by:

```bash
task ansible:inventory:render
```

## Notes
- The inventory renderer is deterministic and can be re-run safely.
- Generated inventory files should remain outside the committed repo state.
