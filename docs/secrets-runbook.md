# Secrets Operations Runbook (Day 2)

## Purpose

This runbook covers operational procedures for secrets management in fouchger-homelab:
- SOPS + age for Git-encrypted configuration state
- OpenBao for dynamic secrets, audit, policy, and PKI
- Unseal workflow, emergency access, backup and restore, and token rotation cadence

## Scope and design intent

SOPS + age is the source of truth for configuration state that must live with the repo, such as:
- API keys rotated manually
- App configuration secrets that do not need to be generated on demand
- Ansible inventory `group_vars` and configuration state

OpenBao is the source of truth for secrets you want to be ephemeral, centrally controlled, and auditable, such as:
- Dynamic database credentials with TTL
- PKI and certificate issuance
- Short-lived tokens
- Centralised audit trails and policy enforcement for multiple admins

## Operational roles

Operator responsibilities typically include:
- Maintaining age recipients and access for admin devices
- Ensuring OpenBao initialisation and unseal process is reliable
- Managing policies, auth methods, and audit configuration
- Running backups and validating restores
- Rotating tokens and keys on a regular cadence

## SOPS + age operations

### Where secrets live
- `state/secrets/sops/` contains encrypted secrets and config state (kept locally under `state/`, which is ignored by Git by default)
- `ansible/group_vars/**` secret files should be SOPS-encrypted where appropriate
- `state/secrets/age/` contains private age identities (not committed to Git)

### Adding a new admin device
1. On the admin device, generate an age identity:
   - `age-keygen -o state/secrets/age/age-key.txt`
2. Extract the public key (recipient) and add it to the recipients list used by the repo.
3. Update `.sops.yaml` to include the new recipient as required.
4. Re-encrypt affected files so all required recipients can decrypt.

Operational note: keep the number of recipients tight. Too many recipients can become governance debt.

### Encrypt a new secrets file
1. Place the file under `state/secrets/sops/` or the relevant Ansible secrets path.
2. Encrypt in place:
   - `sops -e -i <file>`

### Decrypt for use
- `sops -d <file>` (stdout)
- Avoid writing decrypted files to disk unless needed for a controlled workflow.

### Key loss and recovery
If an admin loses the private age identity:
- Remove their recipient from `.sops.yaml`
- Re-encrypt impacted files
- Issue a new identity for that admin device if they remain an authorised operator

## OpenBao Day 2 operations

### Environment variables (operator convenience)
On operator shells, set:
- `export BAO_ADDR=http://127.0.0.1:8200`

If you later move OpenBao behind TLS or a reverse proxy, update BAO_ADDR accordingly.

### Service health
- `systemctl status openbao`
- `bao status`

When sealed, `bao status` will show sealed. This is expected after restarts unless you implement an auto-unseal strategy.

## Unseal workflow

### Standard unseal procedure (manual, recommended for homelab control)
Assumptions:
- OpenBao was initialised with a threshold scheme (eg 3 of 5 keys)
- Unseal keys are stored in a controlled manner, ideally split across admins or secured locations

Steps:
1. Retrieve unseal keys via the encrypted bootstrap artefact:
   - `sops -d state/secrets/openbao/bootstrap.enc.yaml`
2. Provide unseal keys (3 of 5) to OpenBao:
   - `bao operator unseal`
   - Repeat until unseal threshold is met
3. Login:
   - `bao login` (use a non-root operator token where possible)

Operational note: do not use the root token for day-to-day operations. Treat it as break-glass.

### Post-unseal validation checklist
- `bao status` shows unsealed
- Audit is enabled and writing (file audit in `/var/log/openbao/audit.log` if configured)
- Required secret engines are enabled (kv-v2, pki, database as applicable)
- Policies exist and are correct for operator roles

## Emergency access (break-glass)

### What qualifies as break-glass
- Loss of normal operator credentials
- Policy or auth misconfiguration that blocks admin operations
- Recovery after suspected compromise where rapid lock-down is needed

### Break-glass kit
Keep these artefacts offline or strongly protected:
- Root token (initial only, or a sealed break-glass equivalent)
- Unseal keys (split custody recommended)
- A printed minimal runbook for unseal, login, and disable auth methods if needed

### Emergency steps
1. Unseal OpenBao (standard procedure)
2. Login with root token (only if absolutely required)
3. Stabilise:
   - Disable compromised auth methods
   - Rotate affected secrets
   - Review audit logs for suspicious activity
4. Re-establish normal operator access:
   - Recreate policies and non-root admin roles
   - Revoke temporary emergency tokens
5. Document incident outcomes and changes

## Backup and restore

This repo includes Taskfile automation for OpenBao backup and restore:
- Create a backup: `task secrets:openbao:backup`
- Restore a backup: `task secrets:openbao:restore -- FILE=<path>`

These tasks are designed to be safe and consistent by stopping OpenBao briefly during backup and restore.
### What to back up

OpenBao (file storage backend):
- Data directory (default: `/var/lib/openbao/`)
- Config directory (default: `/etc/openbao/`)
- Service unit file (if present: `/etc/systemd/system/openbao.service`)

SOPS + age:
- Encrypted secrets are already in Git
- The critical non-Git item is each admin’s private age identity, which must be protected and backed up separately

### Backup method (recommended)

Preferred approach is an encrypted backup artefact using SOPS:
- `task secrets:openbao:backup`

By default, the backup task:
- Stops OpenBao for a consistent snapshot
- Creates a timestamped tarball in `~/backups/openbao/`
- Encrypts it with SOPS as a binary blob (`.tar.gz.sops`)
- Prunes backups older than 30 days (configurable)

If you need plaintext tarballs (only on encrypted storage), run:
- `task secrets:openbao:backup -- ENCRYPT=0`

Key parameters:
- `BACKUP_DIR` default: `~/backups/openbao`
- `ENCRYPT` default: `1`
- `KEEP_DAYS` default: `30` (use `0` to disable pruning)

### Backup validation

After each backup:
- Confirm the expected file exists in the backup directory
- If encrypted, confirm you can decrypt it on an authorised admin device:
  - `sops --input-type binary --output-type binary -d <file>.sops > /tmp/openbao-restore.tar.gz`
- Optionally list contents without restoring (recommended quarterly):
  - `tar -tzf /tmp/openbao-restore.tar.gz | head`

Operational note: a backup you have not test-restored is a risk, not a control.

### Restore procedure (same host or new host)

Prerequisites:
- You have the backup file (`.tar.gz` or `.tar.gz.sops`)
- The host has OpenBao installed and systemd available
- For encrypted backups, the host has SOPS and the correct age identity available

Steps:
1. Restore via Taskfile:
   - Encrypted backup:
     - `task secrets:openbao:restore -- FILE=~/backups/openbao/openbao-backup-<ts>.tar.gz.sops`
   - Plaintext backup:
     - `task secrets:openbao:restore -- FILE=~/backups/openbao/openbao-backup-<ts>.tar.gz`
2. After restore, check service:
   - `systemctl status openbao`
3. Check seal status:
   - `bao status`
4. If sealed, unseal:
   - `bao operator unseal` (repeat to threshold)
5. Validate:
   - Secrets engines are present
   - Audit logging is enabled and writing
   - Policies and auth methods behave as expected

Important: the restore task overwrites files under `/etc/openbao/` and `/var/lib/openbao/`. Use it only with the correct backup for the correct environment.

## Token rotation cadence and strategy

### Recommended cadence (baseline)
- Root token: never used day-to-day; rotate after any break-glass use or suspected exposure
- Operator/admin tokens: rotate quarterly or faster if the environment changes frequently
- AppRole credentials: rotate on deployment cycles or quarterly
- PKI root and intermediates:
  - Root CA: long-lived, tightly protected, rotate only with a planned ceremony
  - Intermediate CA: rotate on a defined schedule (eg annually), shorter TTL on issued certs
- Database dynamic creds: TTL based, rotate automatically by design

### Practical rotation pattern
1. Create new auth credentials (new tokens/roles)
2. Update dependent systems (Ansible, apps, CI)
3. Revoke old credentials
4. Confirm audit trails capture the changes

## Audit and monitoring

### Audit log handling
- Ensure audit logging is enabled
- Ship logs off-host if you have a log stack, even a lightweight one
- Review access patterns monthly, and during any incidents

### Drift and compliance checks
Monthly checks:
- Are any secrets living in plain text where they should be SOPS-encrypted
- Are OpenBao policies still aligned to current admin and app roles
- Are any long-lived tokens still in use unnecessarily
- Do backups exist and have they been test-restored recently

## Appendix: Common operator commands

OpenBao:
- `bao status`
- `bao operator unseal`
- `bao login`
- `bao token lookup`
- `bao secrets list`
- `bao auth list`
- `bao policy list`

SOPS:
- `sops -d <file>`
- `sops -e -i <file>`

Backup:
 - Encrypted backup to your home directory (default): `secrets:openbao:backup`
 - Plaintext backup (only if the backup destination is already encrypted): `secrets:openbao:backup -- ENCRYPT=0`
 - Restore: `secrets:openbao:restore -- FILE=~/backups/openbao/openbao-backup-<timestamp>.tar.gz.sops`
