# State Directory

## Purpose
The `state/` directory holds local-only runtime data, generated configuration, keys, and encrypted secret material used during homelab bootstrap and operations.

## Notes
- `state/` is intentionally ignored by Git.
- Treat everything under `state/` as machine-local or operator-local.
- Recreate required structure by running `task all` or `task secrets`.
