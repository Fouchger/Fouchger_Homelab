# Fouchger_Homelab# Fouchger_Homelab <!-- omit from toc -->

A Taskfile-driven homelab operations repository for workstation bootstrap, SSH trust setup, secrets management, Proxmox automation, and VM lifecycle support.

- [Install](#install)
- [Secrets Management](#secrets-management)
  - [Quick Start](#quick-start)
    - [Day 1 (Initial Setup)](#day-1-initial-setup)
    - [Day 2 (Ongoing Operations)](#day-2-ongoing-operations)
  - [Runtime Secrets](#runtime-secrets)
  - [Notes](#notes)


## Install

Run from ubuntu server/lxc/vm to install repo

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Fouchger/Fouchger_Homelab/refs/heads/main3/install.sh)"
```

## Repository layout

```text
Taskfile.yml                              Root operator entry point
taskfile/                                 Namespaced Taskfiles
scripts/                                  Shell helpers and installers
docs/                                     Runbooks and supporting documentation
state/                                    Local operator state, secrets, inventory, and generated files
state/config/.env                         Safe non-sensitive config template
state/secrets/passwordspasswords.enc.env  Safe secret key template

