#!/usr/bin/env bash
# bootstrap.sh
# Purpose: Install go-task ("task") if missing, then run the Taskfile bootstrap.

set -euo pipefail

if command -v task >/dev/null 2>&1; then
  echo "go-task already installed: $(task --version)"
else
  echo "Installing go-task (task)..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl tar

  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) task_arch="amd64" ;;
    arm64) task_arch="arm64" ;;
    armhf) task_arch="armv7" ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
  esac

  version="v3.48.0"
  url="https://github.com/go-task/task/releases/download/${version}/task_linux_${task_arch}.tar.gz"

  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/task.tar.gz"
  tar -xzf "$tmp/task.tar.gz" -C "$tmp"
  sudo install -m 0755 "$tmp/task" /usr/local/bin/task
  rm -rf "$tmp"

  echo "Installed: $(task --version)"
fi

task bootstrap "${@:-ENV=dev}"
