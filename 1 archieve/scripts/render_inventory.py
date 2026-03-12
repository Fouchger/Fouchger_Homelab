#!/usr/bin/env python3
"""
# ================================================================
# File: scripts/render_inventory.py
# Purpose:
#   Render an Ansible inventory file from Terraform outputs.
#
# Notes:
#   - The script expects a `terraform output -json` structure that includes
#     the `ansible_inventory` output from the lab environment.
#   - Generated inventory is written as YAML for easy inspection.
# ================================================================
"""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

import yaml


def get_terraform_output(terraform_dir: Path) -> dict:
    command = ["terraform", "-chdir=%s" % terraform_dir, "output", "-json"]
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    payload = json.loads(result.stdout)
    if "ansible_inventory" not in payload:
        raise RuntimeError("Terraform output 'ansible_inventory' was not found.")
    return payload["ansible_inventory"]["value"]


def write_inventory(data: dict, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as handle:
        yaml.safe_dump(data, handle, default_flow_style=False, sort_keys=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Render Ansible inventory from Terraform outputs")
    parser.add_argument("--terraform-dir", required=True, help="Path to the Terraform environment directory")
    parser.add_argument("--output", required=True, help="Path to the rendered inventory file")
    args = parser.parse_args()

    terraform_dir = Path(args.terraform_dir).resolve()
    output_path = Path(args.output).resolve()

    inventory = get_terraform_output(terraform_dir)
    write_inventory(inventory, output_path)


if __name__ == "__main__":
    main()
