# Automation Architecture

## Purpose
This document describes the target automation pattern for the homelab stack.

## Delivery flow
The repository now follows a consistent control flow:

1. Task sources operator configuration and secrets.
2. Terraform provisions the Proxmox guests.
3. Terraform emits structured guest metadata.
4. A rendering step converts Terraform outputs into an Ansible inventory file.
5. Ansible applies base roles and service-specific roles.
6. Post-build service configuration is applied only after the service is online.

## Design principles
- Terraform owns infrastructure lifecycle.
- Ansible owns operating system and application configuration.
- OpenBao remains the source of truth for sensitive runtime material.
- Identity services run on dedicated VMs rather than on `admin01`.
- Service definitions are catalog-driven rather than hard-coded sample guests.

## Service placement
### authentik
- Dedicated Ubuntu VM
- Docker Compose deployment pattern
- Used for application SSO and federation

### FreeIPA
- Dedicated RHEL-compatible VM preferred
- Installed with upstream `ansible-freeipa` roles
- Used for Linux identity, sudo policy, SSH key distribution, and host access control

## Notes
- authentik has an official Terraform provider for in-platform configuration, which is a good follow-on once the service VM is stable. citeturn0search0turn0search9
- FreeIPA publishes supported Ansible roles for server, replica, and client deployment. citeturn0search1turn0search4
- AWX supports multiple authentication methods, including enterprise authentication options, so the repo should treat application SSO separately from Linux host identity. citeturn0search2turn0search5
