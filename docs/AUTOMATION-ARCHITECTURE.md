# Automation Architecture

## Purpose
This document summarises the intended delivery model for the homelab automation stack.

## Delivery flow
1. Task provides the operator entry points.
2. Secrets and local operator state are bootstrapped first.
3. Proxmox foundation access is prepared through the API-user workflow.
4. Packer builds the preferred VM template catalogue for Linux, network, appliance, and Windows guests.
5. Proxmox host-side template bootstrap remains available as a fallback seeding path.
6. Terraform clones and wires workloads from stable Proxmox template identifiers.
7. Terraform outputs feed inventory generation for later configuration management.
8. Ansible applies the desired base operating system and service roles.
9. Service providers and APIs are configured only after the base platform is reachable.

## Practical repository split
### Active root layer
The active root layer is the control plane for operator workflows, bootstrap, secrets, Proxmox access, and curated template builds.

### Archived layer
The `1 archieve/` layer preserves the earlier Terraform and Ansible implementation so it can be selectively reintroduced once the root repo shape is settled.

## Template strategy
The current preferred template catalogue is maintained in `packer/` and now covers:

- Ubuntu 22.04, 24.04, and 25.04
- Rocky Linux 9 and 10
- Talos Linux 1.12
- OPNsense 25.7 and OPNsense 26.1
- Alpine Linux 3.21 and 3.22
- Windows Server 2022 and 2025
- Windows 11

This keeps guest-image lifecycle work separate from service provisioning and gives the later Terraform layer a stable clone source.
