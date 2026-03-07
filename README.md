# Fouchger Homelab

## Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Fouchger/Fouchger_Homelab/refs/heads/branch1/install.sh)"
```

## Bootstrap
Run the standard bootstrap flow:

```bash
task all
```

## Common tasks
Run the secrets bootstrap only:

```bash
task secrets
```

Run the OpenBao bootstrap sequence as part of the main flow:

```bash
ENABLE_OPENBAO_BOOTSTRAP=1 task all
```

## Notes
- Local runtime data and secrets live under `state/`.
- The `state/` directory is ignored by Git and must not be committed.
- An example local environment file is stored at `config/examples/state.env.example`.
