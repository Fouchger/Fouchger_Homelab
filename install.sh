#!/usr/bin/env bash
# ################################################################
# File: install.sh
# Created: 2026/02/08
# Updated: 2026/02/28
# Description:
#   Production-ready bootstrap installer for Fouchger/homelab.
# Notes:
#   - Debian/Ubuntu oriented (apt-get).
#   - Clones or updates the repo using GitHub CLI (gh) when available.
#   - Falls back to plain git clone when gh is unavailable or not authenticated.
#   - Supports non-interactive runs via: NONINTERACTIVE=1 (defaults to SETUP=prod).
#   - Optionally writes install metadata to: $ROOT_DIR/state/configs/.env
#   - Update flow preserves functionality but is safer:
#       - If local changes exist, user can choose: commit, stash, or abort.
#
# Defaults:
#   SETUP="${SETUP:-prod}"              # prod or dev
#   HOMELAB_BRANCH="${HOMELAB_BRANCH:-main}"
#   HOMELAB_GIT_PROTOCOL="${HOMELAB_GIT_PROTOCOL:-https}"  # https or ssh
#   NONINTERACTIVE="${NONINTERACTIVE:-0}" # 1 disables prompts where feasible
#
# Example:
#   ./install.sh
#   SETUP=dev HOMELAB_BRANCH=main ./install.sh
#   NONINTERACTIVE=1 ./install.sh
# ################################################################

set -Eeuo pipefail
IFS=$'\n\t'

# ----------------------------
# Simple logging helpers
# ----------------------------
_info()    { printf '%s\n' "INFO: $*"; }
_warn()    { printf '%s\n' "WARN: $*"; }
_error()   { printf '%s\n' "ERROR: $*" >&2; }
_success() { printf '%s\n' "SUCCESS: $*"; }

# ----------------------------
# Globals used across steps
# ----------------------------
REPO_SLUG="Fouchger/homelab"
BRANCH="${HOMELAB_BRANCH:-main}"
TARGET_DIR=""
ROOT_DIR=""
NONINTERACTIVE="${NONINTERACTIVE:-0}"

trap '_error "Install failed at line $LINENO (exit code: $?)"' ERR

_banner() {
  echo "=========================================================="
  echo "       Fouchger Homelab installer (bootstrap phase)       "
  echo "=========================================================="
}

# ----------------------------
# Privilege + apt helpers
# ----------------------------
_have_sudo() { command -v sudo >/dev/null 2>&1; }

_as_root() {
  if _have_sudo; then
    sudo -E "$@"
  else
    "$@"
  fi
}

_apt_update() {
  local front=""
  if [[ "${NONINTERACTIVE}" == "1" ]]; then
    front="DEBIAN_FRONTEND=noninteractive"
  fi
  _as_root env ${front} apt-get update -y
}

_apt_install() {
  local front=""
  if [[ "${NONINTERACTIVE}" == "1" ]]; then
    front="DEBIAN_FRONTEND=noninteractive"
  fi
  # shellcheck disable=SC2086
  _as_root env ${front} apt-get install -y --no-install-recommends "$@"
}

_ensure_cmd_or_install() {
  local cmd="${1:?Missing command}"
  shift
  local pkg="${1:?Missing package}"
  shift || true

  if command -v "${cmd}" >/dev/null 2>&1; then
    return 0
  fi

  _info "${cmd} not found. Installing ${pkg}..."
  _apt_update
  _apt_install "${pkg}" "$@"
}

# ----------------------------
# Determine if we can use gh
# ----------------------------
_gh_usable() {
  command -v gh >/dev/null 2>&1 || return 1

  # Common non-interactive tokens
  if [[ -n "${GITHUB_TOKEN:-}" || -n "${GH_TOKEN:-}" ]]; then
    return 0
  fi

  # Avoid noisy output
  gh auth status -h github.com >/dev/null 2>&1
}

# ----------------------------
# Ensure basic deps
# ----------------------------
_ensure_prereqs() {
  _ensure_cmd_or_install git git
  _ensure_cmd_or_install curl curl ca-certificates
  _ensure_cmd_or_install ca-certificates ca-certificates
}

# ----------------------------
# Choose SETUP (unless provided)
# ----------------------------
_set_environment() {
  if [[ -n "${SETUP:-}" ]]; then
    case "${SETUP}" in
      prod|dev) _info "SETUP already set to: ${SETUP}"; return 0 ;;
      *) _error "Invalid SETUP='${SETUP}'. Must be 'prod' or 'dev'."; return 1 ;;
    esac
  fi

  if [[ "${NONINTERACTIVE}" == "1" ]]; then
    SETUP="prod"
    export SETUP
    _info "NONINTERACTIVE=1 set. Defaulting SETUP to: ${SETUP}"
    return 0
  fi

  while true; do
    read -r -p "Select SETUP environment [prod/dev] (default: prod): " SETUP
    SETUP="${SETUP:-prod}"
    case "$SETUP" in
      prod|dev) break ;;
      *) echo "Invalid choice. Please enter 'dev' or 'prod'." ;;
    esac
  done

  export SETUP
  _info "SETUP set to: $SETUP"
}

# ----------------------------
# Resolve install directory
# ----------------------------
_set_target_dir() {
  case "${SETUP:-}" in
    prod) TARGET_DIR="$HOME/app/homelab" ;;
    dev)  TARGET_DIR="$HOME/Github/homelab" ;;
    *)    _error "SETUP must be 'prod' or 'dev'."; return 1 ;;
  esac

  mkdir -p "$(dirname "$TARGET_DIR")"
}

# ----------------------------
# Clone repo (gh if possible, else git)
# Safer branch handling: clone then checkout/fetch to branch explicitly
# ----------------------------
_clone_repo() {
  local protocol="${HOMELAB_GIT_PROTOCOL:-https}"
  local url=""

  if _gh_usable; then
    _info "Using GitHub CLI (gh) to clone ${REPO_SLUG}"
    gh repo clone "${REPO_SLUG}" "${TARGET_DIR}"
    # Ensure desired branch
    pushd "${TARGET_DIR}" >/dev/null
    _info "Fetching and checking out branch '${BRANCH}'..."
    git fetch --prune origin
    if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
      git checkout -B "${BRANCH}" "origin/${BRANCH}"
    else
      _error "Branch '${BRANCH}' not found on origin. Clone stopped."
      popd >/dev/null
      return 1
    fi
    popd >/dev/null
    return 0
  fi

  _warn "gh is not available or not authenticated. Falling back to git clone."

  case "${protocol}" in
    ssh)   url="git@github.com:${REPO_SLUG}.git" ;;
    https) url="https://github.com/${REPO_SLUG}.git" ;;
    *)
      _warn "Unknown HOMELAB_GIT_PROTOCOL='${protocol}', defaulting to https."
      url="https://github.com/${REPO_SLUG}.git"
      ;;
  esac

  _info "Cloning via git from: ${url} (branch: ${BRANCH})"
  git clone --branch "${BRANCH}" --single-branch "${url}" "${TARGET_DIR}"
}

# ----------------------------
# Update existing repo safely
# Keeps functionality, but offers: commit, stash, or abort
# ----------------------------
_update_repo() {
  if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    _error "Target exists but is not a git repository: ${TARGET_DIR}"
    return 1
  fi

  pushd "${TARGET_DIR}" >/dev/null

  _info "Fetching updates..."
  git fetch --prune origin

  _info "Checking out branch '${BRANCH}'..."
  if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git checkout "${BRANCH}"
  elif git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
    git checkout -b "${BRANCH}" "origin/${BRANCH}"
  else
    _error "Branch '${BRANCH}' not found on origin. Update stopped."
    popd >/dev/null
    return 1
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    _warn "Local changes detected in ${TARGET_DIR}."

    local action=""
    if [[ "${NONINTERACTIVE}" == "1" ]]; then
      # Production-safe default in automation: stash and continue
      action="s"
      _warn "NONINTERACTIVE=1 set. Defaulting to: stash local changes."
    else
      echo "Choose how to handle local changes:"
      echo "  [c] Commit changes and continue"
      echo "  [s] Stash changes and continue"
      echo "  [a] Abort update (recommended if unsure)"
      while true; do
        read -r -p "Action [c/s/a] (default: a): " action
        action="${action:-a}"
        case "${action}" in
          c|C|s|S|a|A) break ;;
          *) echo "Please enter c, s, or a." ;;
        esac
      done
    fi

    case "${action}" in
      a|A)
        _warn "Update stopped. Please commit or stash changes and try again."
        popd >/dev/null
        return 2
        ;;
      s|S)
        _info "Stashing local changes..."
        git stash push -u -m "bootstrap: auto-stash before update ($(date -Is))"
        _success "Changes stashed."
        ;;
      c|C)
        local commit_msg=""
        if [[ "${NONINTERACTIVE}" == "1" ]]; then
          commit_msg="WIP: local changes"
        else
          read -r -p "Commit message (default: 'WIP: local changes'): " commit_msg
          commit_msg="${commit_msg:-WIP: local changes}"
        fi

        git add -A
        if ! git diff --cached --quiet; then
          git commit -m "${commit_msg}"
          _info "Changes committed."
        else
          _warn "Nothing staged to commit. Update stopped."
          popd >/dev/null
          return 2
        fi
        ;;
    esac
  fi

  _info "Pulling latest (rebase + autostash)..."
  git pull --rebase --autostash origin "${BRANCH}"

  popd >/dev/null
}

# ----------------------------
# Clone-or-update wrapper
# ----------------------------
_clone_or_update_homelab_repo() {
  _ensure_prereqs
  _set_target_dir

  if [[ ! -d "${TARGET_DIR}" ]]; then
    _info "Cloning ${REPO_SLUG} (${BRANCH}) into ${TARGET_DIR}"
    _clone_repo
    _success "Repository cloned: ${TARGET_DIR}"
    return 0
  fi

  _info "Repository directory exists. Updating: ${TARGET_DIR}"
  _update_repo
  _success "Repository updated: ${TARGET_DIR}"
}

# ----------------------------
# Find ROOT_DIR by marker (fallback to TARGET_DIR)
# ----------------------------
_find_root_dir() {
  local marker=".root_marker"
  local dir="${TARGET_DIR}"

  dir="$(cd "${dir}" 2>/dev/null && pwd)" || return 1

  while :; do
    if [[ -f "${dir}/${marker}" ]]; then
      ROOT_DIR="${dir}"
      export ROOT_DIR
      _info "ROOT_DIR detected: ${ROOT_DIR}"
      return 0
    fi

    if [[ "${dir}" == "/" ]]; then
      break
    fi

    dir="$(dirname "${dir}")"
  done

  ROOT_DIR="${TARGET_DIR}"
  export ROOT_DIR
  _warn "Marker ${marker} not found. Falling back to ROOT_DIR=${ROOT_DIR}"
  return 0
}

# ----------------------------
# Normalise executable permissions
# ----------------------------
_ensure_executables() {
  local root="${ROOT_DIR}"

  _info "Normalising executable permissions under: ${root}"

  # Make all *.sh executable
  while IFS= read -r -d '' file_path; do
    chmod +x "${file_path}" 2>/dev/null || true
  done < <(find "${root}" -type f -name "*.sh" -print0)

  # Also apply configs/executable.list if present
  local list_file="${root}/configs/executable.list"
  if [[ -f "${list_file}" ]]; then
    while IFS= read -r line || [[ -n "${line}" ]]; do
      line="${line%$'\r'}"
      [[ -z "${line}" ]] && continue
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue

      local target_path="${root}/${line}"
      if [[ -f "${target_path}" ]]; then
        chmod +x "${target_path}" 2>/dev/null || true
      else
        _warn "executable.list entry not found: ${line}"
      fi
    done < "${list_file}"
  fi

  _success "Executable permissions normalised"
}

# ----------------------------
# Write/update env metadata (optional but useful)
# ----------------------------
_write_update_env_file() {
  local env_dir="${ROOT_DIR}/state/configs"
  local env_file="${env_dir}/.env"

  mkdir -p "${env_dir}"

  if [[ ! -f "${env_file}" ]]; then
    cat >"${env_file}" <<'EOF'
# ################################################################
# File: .env
# Created: 2026/02/08
# Description:
#   Local environment settings for homelab bootstrap/runtime.
# Notes:
#   - This file may be updated by install scripts.
#   - Keep values simple KEY=VALUE format (dotenv compatible).
# ################################################################

EOF
    _info "Created ${env_file}"
  fi

  _dotenv_upsert() {
    local key="${1:?Missing key}"
    local value="${2-}"
    local file="${3:?Missing file}"

    # Basic guardrails: avoid multi-line values in dotenv
    if printf '%s' "${value}" | grep -q $'\n'; then
      _warn "Skipping ${key} update: multi-line value is not dotenv-safe."
      return 0
    fi

    local esc_value
    esc_value="$(printf '%s' "${value}" | sed -e 's/[\/&]/\\&/g')"

    if grep -qE "^[[:space:]]*${key}=" "${file}"; then
      local tmp
      tmp="$(mktemp)"
      sed -E "s|^[[:space:]]*${key}=.*|${key}=${esc_value}|" "${file}" >"${tmp}" && mv "${tmp}" "${file}"
    else
      printf '%s=%s\n' "${key}" "${value}" >>"${file}"
    fi
  }

  _dotenv_upsert "ROOT_DIR" "${ROOT_DIR}" "${env_file}"
  _dotenv_upsert "REPO_DIR" "${TARGET_DIR}" "${env_file}"
  _dotenv_upsert "GITHUB_REPO" "${REPO_SLUG}" "${env_file}"
  _dotenv_upsert "GITHUB_BRANCH" "${BRANCH}" "${env_file}"
  _dotenv_upsert "SETUP" "${SETUP:-prod}" "${env_file}"
  _dotenv_upsert "HOMELAB_BRANCH" "${HOMELAB_BRANCH:-main}" "${env_file}"
  _dotenv_upsert "HOMELAB_GIT_PROTOCOL" "${HOMELAB_GIT_PROTOCOL:-https}" "${env_file}"
  _dotenv_upsert "NONINTERACTIVE" "${NONINTERACTIVE}" "${env_file}"

  _success "Updated ${env_file}"
}

# ----------------------------
# Install Task (taskfile) securely and idempotently
# Notes:
#   - Still uses upstream installer, but with guardrails.
#   - Avoids breaking environments without sudo.
#   - Uses apt-get in a non-interactive safe way.
# ----------------------------
_taskfile_install() {
  if command -v task >/dev/null 2>&1; then
    _info "Task is already installed."
    return 0
  fi

  _info "Installing Task (taskfile)..."

  _ensure_cmd_or_install curl curl ca-certificates
  _ensure_cmd_or_install gpg gpg

  # Ensure apt transport basics exist
  _ensure_cmd_or_install apt-get apt

  # Run upstream setup script with curl fail-fast flags
  # -f: fail on HTTP errors, -S: show error, -L: follow redirects
  # --proto and --tlsv1.2 reduce downgrade risk
  # retry for resilience
  curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 1 \
    'https://dl.cloudsmith.io/public/task/task/setup.deb.sh' \
    | _as_root bash

  _apt_update
  _apt_install task

  if command -v task >/dev/null 2>&1; then
    _success "Task installed."
  else
    _error "Task install failed."
    return 1
  fi
}

# ----------------------------
# Main
# ----------------------------
_banner
_set_environment
_clone_or_update_homelab_repo
_find_root_dir
_ensure_executables

# Keep this if other scripts depend on state/configs/.env
_write_update_env_file

_info "Bootstrap summary:"
_info "  TARGET_DIR: ${TARGET_DIR}"
_info "  ROOT_DIR:   ${ROOT_DIR}"
_info "  BRANCH:     ${BRANCH}"
_info "  SETUP:      ${SETUP:-prod}"
_info "  ENV_FILE:   ${ROOT_DIR}/state/configs/.env"

_success "Bootstrap complete. Repo is ready at: ${TARGET_DIR}"

# Install taskfile tooling (optional but useful)
_taskfile_install
