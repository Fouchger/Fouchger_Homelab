# Automation Architecture

## Purpose
This document describes the target automation pattern for the homelab stack.

## Delivery flow
The repository follows a consistent control flow:

1. Task sources operator configuration and secrets.
2. Template bootstrap is treated as a separate lifecycle from service provisioning.
3. Terraform provisions the Proxmox guests used for live services.
4. Terraform emits structured guest metadata.
5. A rendering step converts Terraform outputs into an Ansible inventory file.
6. Ansible applies base roles and service-specific roles.
7. Post-build service configuration is applied only after the service is online.

## Design principles
- Terraform owns infrastructure lifecycle.
- Ansible owns operating system and application configuration.
- OpenBao remains the source of truth for sensitive runtime material.
- Identity services run on dedicated VMs rather than on `admin01`.
- Service definitions are catalog-driven rather than hard-coded sample guests.
- Steady-state applies should avoid unnecessary dependence on external image downloads.

## Service placement
### authentik
- Dedicated Ubuntu VM
- Docker Compose deployment pattern
- Used for application SSO and federation

### FreeIPA
- Dedicated RHEL-compatible VM preferred
- Installed with upstream `ansible-freeipa` roles
- Used for Linux identity, sudo policy, SSH key distribution, and host access control

## Platform strategy
### Template bootstrap
Template images and template VMs are infrastructure seed artefacts.
They change infrequently and should be managed deliberately.

### Service lifecycle
Service VMs should be cloned from known-good template IDs so that normal `terraform apply` runs stay deterministic and operationally simple.
