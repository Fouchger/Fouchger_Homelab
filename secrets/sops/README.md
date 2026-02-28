# Encrypted secrets (SOPS)

Store Git-encrypted configuration state here (YAML/JSON/ENV/INI).

Examples:
- API keys rotated manually
- app config secrets
- Ansible group_vars secrets files

Do not store age private keys here. Those live under secrets/age/ which is ignored by Git.
