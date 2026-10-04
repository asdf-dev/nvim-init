#!/bin/sh
set -eu

# asdf-dev/nvim-init bootstrap installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/asdf-dev/nvim-init/main/install.sh | sh

REPO_RAW_URL="${NVIM_INIT_URL:-https://raw.githubusercontent.com/asdf-dev/nvim-init/main/init.lua}"
MIN_NVIM_VERSION="${MIN_NVIM_VERSION:-0.11.2}"
LAZY_REPO="https://github.com/folke/lazy.nvim.git"
LAZY_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'WARNING: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

version_at_least() {
  # Arguments: current required
  current="$1"
  required="$2"

  current_major=$(printf '%s\n' "$current" | cut -d. -f1)
  current_minor=$(printf '%s\n' "$current" | cut -d. -f2)
  current_patch=$(printf '%s\n' "$current" | cut -d. -f3)
  required_major=$(printf '%s\n' "$required" | cut -d. -f1)
  required_minor=$(printf '%s\n' "$required" | cut -d. -f2)
  required_patch=$(printf '%s\n' "$required" | cut -d. -f3)

  [ "${current_major:-0}" -gt "${required_major:-0}" ] ||
    {
      [ "${current_major:-0}" -eq "${required_major:-0}" ] &&
      [ "${current_minor:-0}" -gt "${required_minor:-0}" ]
    } ||
    {
      [ "${current_major:-0}" -eq "${required_major:-0}" ] &&
      [ "${current_minor:-0}" -eq "${required_minor:-0}" ] &&
      [ "${current_patch:-0}" -ge "${required_patch:-0}" ]
    }
}

nvim_version() {
  "$1" --version 2>/dev/null |
    sed -n '1s/^NVIM v\([0-9][0-9.]*\).*/\1/p' |
    head -n 1
}

ensure_sudo() {
  command_exists sudo || die "sudo is required to install missing Linux packages."
}

install_linux_packages() {
  missing=""
  for cmd in "$@"; do
    command_exists "$cmd" || missing="$missing $cmd"
  done

  [ -z "$missing" ] && return 0

  if command_exists apt-get; then
    log "Installing Linux dependencies with apt"
    ensure_sudo
    sudo apt-get update
    sudo apt-get install -y git curl ca-certificates build-essential
  elif command_exists dnf; then
    log "Installing Linux dependencies with dnf"
    ensure_sudo
    sudo dnf install -y git curl ca-certificates gcc gcc-c++ make
  elif command_exists pacman; then
    log "Installing Linux dependencies with pacman"
    ensure_sudo
    sudo pacman -Sy --needed --noconfirm git curl ca-certificates base-devel
  elif command_exists zypper; then
    log "Installing Linux dependencies with zypper"
    ensure_sudo
    sudo zypper --non-interactive install git curl ca-certificates gcc gcc-c++ make
  elif command_exists apk; then
    log "Installing Linux dependencies with apk"
    ensure_sudo
    sudo apk add git curl ca-certificates build-base
  else
    die "Could not identify a supported Linux package manager. Install git, curl, a C compiler, and make manually."
  fi
}

install_macos_dependencies() {
  command_exists git && command_exists curl && return 0

  if command_exists brew; then
    log "Installing macOS dependencies with Homebrew"
    brew install git curl
    return 0
  fi

  die "git/curl are required. Install Xcode Command Line Tools or Homebrew, then run this installer again."
}

install_nvim_archive() {
  os="$1"
  arch="$2"

  case "$os:$arch" in
    Darwin:arm64) asset="nvim-macos-arm64.tar.gz"; dir="nvim-macos-arm64" ;;
    Darwin:x86_64) asset="nvim-macos-x86_64.tar.gz"; dir="nvim-macos-x86_64" ;;
    Linux:arm64) asset="nvim-linux-arm64.tar.gz"; dir="nvim-linux-arm64" ;;
    Linux:x86_64) asset="nvim-linux-x86_64.tar.gz"; dir="nvim-linux-x86_64" ;;
    *) die "Unsupported platform: $os/$arch" ;;
  esac

  local_root="$HOME/.local"
  nvim_root="$local_root/nvim"
  bin_root="$local_root/bin"
  tmp_dir=$(mktemp -d)

  trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

  log "Downloading official Neovim release: $asset"
  curl -fL --retry 3 --retry-delay 1 \
    "https://github.com/neovim/neovim/releases/latest/download/$asset" \
    -o "$tmp_dir/nvim.tar.gz"

  rm -rf "$nvim_root"
  mkdir -p "$local_root" "$bin_root"
  tar -xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"

  mv "$tmp_dir/$dir" "$nvim_root"
  ln -sf "$nvim_root/bin/nvim" "$bin_root/nvim"

  # Make the current shell use the freshly installed binary.
  case ":${PATH:-}:" in
    *":$bin_root:"*) ;;
    *) PATH="$bin_root:$PATH"; export PATH ;;
  esac

  add_path_to_shell_rc "$bin_root"
}

add_path_to_shell_rc() {
  bin_root="$1"
  line='export PATH="$HOME/.local/bin:$PATH"'

  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [ -f "$rc" ] && ! grep -Fqs "$line" "$rc"; then
      printf '\n# Added by asdf-dev/nvim-init installer\n%s\n' "$line" >> "$rc"
    fi
  done
}

install_or_update_nvim() {
  os=$(uname -s)
  arch=$(uname -m)

  if command_exists nvim; then
    current=$(nvim_version "$(command -v nvim)" || true)
    if [ -n "$current" ] && version_at_least "$current" "$MIN_NVIM_VERSION"; then
      log "Neovim $current is already installed"
      return 0
    fi

    if [ -n "$current" ]; then
      warn "Neovim $current is too old; $MIN_NVIM_VERSION or newer is required."
    else
      warn "Could not determine the installed Neovim version."
    fi
  else
    log "Neovim is not installed"
  fi

  if [ "$os" = "Darwin" ] && command_exists brew; then
    log "Installing/upgrading Neovim with Homebrew"
    brew install neovim 2>/dev/null || brew upgrade neovim
    return 0
  fi

  install_nvim_archive "$os" "$arch"
}

backup_config() {
  config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  new_init="$1"

  [ -e "$config_dir" ] || return 0
  [ -f "$config_dir/init.lua" ] || {
    timestamp=$(date '+%Y%m%d-%H%M%S')
    backup_dir="${config_dir}.backup-${timestamp}"
    log "Backing up existing Neovim config"
    mv "$config_dir" "$backup_dir"
    printf 'Backup: %s\\n' "$backup_dir"
    return 0
  }

  if cmp -s "$config_dir/init.lua" "$new_init"; then
    return 0
  fi

  timestamp=$(date '+%Y%m%d-%H%M%S')
  backup_dir="${config_dir}.backup-${timestamp}"
  log "Backing up existing Neovim config"
  mv "$config_dir" "$backup_dir"
  printf 'Backup: %s\\n' "$backup_dir"
}

install_config() {
  config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  init_file="$config_dir/init.lua"
  tmp_file="${TMPDIR:-/tmp}/nvim-init.lua.$$"

  log "Downloading init.lua"
  curl -fL --retry 3 --retry-delay 1 "$REPO_RAW_URL" -o "$tmp_file"

  backup_config "$tmp_file"
  mkdir -p "$config_dir"

  if [ -f "$init_file" ] && cmp -s "$init_file" "$tmp_file"; then
    rm -f "$tmp_file"
    log "init.lua is already up to date"
    return 0
  fi

  mv "$tmp_file" "$init_file"
  chmod 0644 "$init_file"
}

install_lazy() {
  if [ -d "$LAZY_PATH/.git" ]; then
    log "lazy.nvim is already installed"
    return 0
  fi

  if [ -e "$LAZY_PATH" ]; then
    die "$LAZY_PATH exists but is not a git repository. Remove or move it, then rerun the installer."
  fi

  log "Installing lazy.nvim"
  mkdir -p "$(dirname "$LAZY_PATH")"
  git clone --filter=blob:none --branch=stable "$LAZY_REPO" "$LAZY_PATH"
}

verify() {
  command_exists nvim || die "Neovim installation completed, but 'nvim' is not on PATH in this shell."

  current=$(nvim_version "$(command -v nvim)" || true)
  [ -n "$current" ] || die "Could not determine Neovim version after installation."
  version_at_least "$current" "$MIN_NVIM_VERSION" ||
    die "Neovim $current is still too old; $MIN_NVIM_VERSION or newer is required."

  [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" ] ||
    die "init.lua was not installed."

  [ -d "$LAZY_PATH" ] ||
    die "lazy.nvim was not installed."
}

main() {
  case "$(uname -s)" in
    Darwin)
      install_macos_dependencies
      ;;
    Linux)
      install_linux_packages git curl make cc
      ;;
    *)
      die "This installer supports macOS and Linux/WSL. On native Windows, use WSL or install Neovim manually."
      ;;
  esac

  install_or_update_nvim
  install_lazy
  backup_config
  install_config
  verify

  log "Installation complete"
  printf '\nRun:\n\n  nvim\n\n'
  printf 'On first launch, lazy.nvim will install/update the plugins from init.lua.\n'
  printf 'Run :checkhealth if anything looks wrong.\n\n'
}

main "$@"
