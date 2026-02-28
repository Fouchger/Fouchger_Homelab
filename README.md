# Fouchger Homelab

Bootstrap and day-one tooling for the Fouchger homelab environment (Debian/Ubuntu focused).

## Quick start

Run the installer (clones or updates the repo, then installs Task):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Fouchger/Fouchger_Homelab/refs/heads/main/install.sh)"
```

Non-interactive mode (safe default behaviour, assumes `SETUP=prod` and stashes local changes on update):

```bash
NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Fouchger/Fouchger_Homelab/refs/heads/main/install.sh)"
```

## Prerequisites

You will typically need:

1. A Debian/Ubuntu based host with `apt-get`.
2. Sudo access for package installs.
3. Outbound internet access for repository and installer downloads.

## Task usage

From the repository root:

```bash
task -l
```

### Core commands

System bootstrap (runs upgrade, Python3, pipx, Ansible, Terraform, Packer, code-server):

```bash
task bootstrap
```

Upgrade only:

```bash
task bootstrap:upgrade
```

Install Python and pipx only:

```bash
task bootstrap:python3
task bootstrap:pipx
```

Install Ansible (via pipx):

```bash
task bootstrap:ansible
```

Install Terraform and Packer (via HashiCorp apt repo):

```bash
task bootstrap:terraform
task bootstrap:packer
```

Install code-server (standard installer by default):

```bash
task bootstrap:code-server
```

Install code-server using the Proxmox community script (only when running in a VM or container):

```bash
USE_PROXMOX_SCRIPT=1 task bootstrap:code-server
```

### Git and GitHub CLI authentication

Install Git and GitHub CLI if required, authenticate `gh` using a Fine-grained PAT, and configure Git to use `gh` credentials:

```bash
task scm:bootstrap
```

If you want to run the steps separately:

```bash
task scm:install
task scm:auth
task scm:status
```

For automation, prefer providing the token as an environment variable:

```bash
export GITHUB_TOKEN="<your fine-grained PAT>"
task scm:auth:gh
```

### Shared guardrails

Lightweight checks you can compose into other tasks:

```bash
task lib:ensure-linux
task lib:require-apt
task lib:require-sudo
task lib:require-virtualised
```

## Notes and guardrails

1. `state/configs/.env` is a local runtime file and should not be committed.
2. If you run the installer on a repo with local changes, it will prompt you to commit, stash, or abort. In non-interactive runs it defaults to stashing.
3. The Proxmox code-server script is intentionally gated to VM or container environments.
