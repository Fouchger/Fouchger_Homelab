#!/usr/bin/env bash
# ################################################################
# File: install.sh
# Created: 2026/02/27
# Description:
#   Bare-minimum bootstrap to:
#     1) Install prerequisites to clone the repo
#     2) Clone or update https://github.com/Fouchger/Fouchger_Homelab (branch: main)
#     3) Install go-task (task) if missing
#
# Notes:
#   - Debian/Ubuntu oriented.
#   - Uses HTTPS clone (no gh, no SSH).
#   - Repo location:
#       SETUP=prod -> $HOME/app/Fouchger_Homelab
#       SETUP=dev  -> $HOME/Github/Fouchger_Homelab
# ################################################################

set -euo pipefail

REPO_URL="https://github.com/Fouchger/Fouchger_Homelab"
REPO_BRANCH="main"
SETUP="${SETUP:-prod}"

_info()  { printf '%s\n' "INFO: $*"; }
_warn()  { printf '%s\n' "WARN: $*"; }
_error() { printf '%s\n' "ERROR: $*" >&2; }

_as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
    return $?
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
    return $?
  fi

  _error "This action requires root privileges but sudo is not available."
  return 1
}

_apt_install() {
  # Usage: _apt_install pkg1 pkg2 ...
  _as_root apt-get update -y
  _as_root apt-get install -y "$@"
}

_require_git_for_https_clone() {
  # Minimal prerequisites for HTTPS cloning + downloads
  local pkgs=(ca-certificates curl git)

  local missing=()
  for p in "${pkgs[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done

  if (( ${#missing[@]} > 0 )); then
    _info "Installing prerequisites: ${missing[*]}"
    _apt_install "${missing[@]}"
  else
    _info "Prerequisites already present."
  fi
}

_pick_target_dir() {
  case "$SETUP" in
    prod) echo "$HOME/app/Fouchger_Homelab" ;;
    dev)  echo "$HOME/Github/Fouchger_Homelab" ;;
    *)
      _error "Invalid SETUP '${SETUP}'. Use 'prod' or 'dev'."
      exit 1
      ;;
  esac
}

_clone_or_update_repo() {
  local target_dir="$1"

  mkdir -p "$(dirname "$target_dir")"

  if [[ ! -d "$target_dir" ]]; then
    _info "Cloning ${REPO_URL} (branch: ${REPO_BRANCH}) into ${target_dir}"
    git clone --branch "${REPO_BRANCH}" --single-branch "${REPO_URL}" "${target_dir}"
    return 0
  fi

  if [[ ! -d "$target_dir/.git" ]]; then
    _error "Target exists but is not a git repository: $target_dir"
    exit 1
  fi

  _info "Updating existing repo in ${target_dir}"
  pushd "$target_dir" >/dev/null
  git fetch --prune origin
  git checkout "${REPO_BRANCH}"
  git pull --rebase --autostash origin "${REPO_BRANCH}"
  popd >/dev/null
}

_install_task_if_missing() {
  if command -v task >/dev/null 2>&1; then
    echo "go-task already installed: $(task --version)"
    return 0
  fi

  echo "Installing go-task (task)..."
  _apt_install ca-certificates curl tar

  local arch task_arch version url tmp
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) task_arch="amd64" ;;
    arm64) task_arch="arm64" ;;
    armhf) task_arch="armv7" ;;
    *)
      echo "Unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac

  version="v3.48.0"
  url="https://github.com/go-task/task/releases/download/${version}/task_linux_${task_arch}.tar.gz"

  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/task.tar.gz"
  tar -xzf "$tmp/task.tar.gz" -C "$tmp"
  _as_root install -m 0755 "$tmp/task" /usr/local/bin/task
  rm -rf "$tmp"

  echo "Installed: $(task --version)"
}

main() {
  _info "Bootstrap starting (SETUP=${SETUP})"
  _require_git_for_https_clone

  local target_dir
  target_dir="$(_pick_target_dir)"
  _clone_or_update_repo "$target_dir"

  _install_task_if_missing

  _info "Done."
  _info "Repo location: ${target_dir}"
}

main "$@"
