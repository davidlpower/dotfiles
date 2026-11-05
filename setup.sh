#!/usr/bin/env bash
# Dev-box setup for Ubuntu/Debian (WSL is fine). Safe to re-run.
#
# Usage:  ./setup.sh              core Python dev setup
#         ./setup.sh --firmware   also install QMK keyboard firmware tooling
#
# Expects a file named "bashrc" next to this script.
set -euo pipefail

FIRMWARE=0
for arg in "$@"; do
  case "$arg" in
    --firmware) FIRMWARE=1 ;;
    -h|--help)  sed -n '2,7p' "$0"; exit 0 ;;
    *)          echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log()  { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Make freshly installed tools visible to the rest of this script
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---------------------------------------------------------------------------
log "apt packages"
sudo apt-get update
sudo apt-get install -y \
  build-essential git curl make htop \
  fzf bat fd-find bind9-dnsutils

# ---------------------------------------------------------------------------
log "uv"
if have uv; then
  echo "uv already installed: $(uv --version)  (update with: uv self update)"
else
  # UV_NO_MODIFY_PATH: the shared bashrc already manages PATH
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

# ---------------------------------------------------------------------------
log "Python versions (managed by uv)"
uv python install 3.10 3.14 3.15

# ---------------------------------------------------------------------------
log "uv tools"
for tool in ipython ruff; do
  uv tool install "$tool"
done

# ---------------------------------------------------------------------------
log "Claude Code CLI"
if have claude; then
  echo "claude already installed: $(claude --version)"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi

# ---------------------------------------------------------------------------
log "~/.bashrc"
src="$REPO_DIR/bashrc"
if [ ! -f "$src" ]; then
  echo "Missing $src" >&2
  exit 1
fi
if cmp -s "$src" "$HOME/.bashrc"; then
  echo "~/.bashrc already up to date"
else
  if [ -f "$HOME/.bashrc" ]; then
    backup="$HOME/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$HOME/.bashrc" "$backup"
    echo "Backed up old bashrc to $backup"
  fi
  cp "$src" "$HOME/.bashrc"
  echo "Installed new ~/.bashrc"
fi

# ---------------------------------------------------------------------------
if [ "$FIRMWARE" -eq 1 ]; then
  log "firmware: compilers and flashing tools"
  sudo apt-get install -y \
    gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi \
    gcc-avr binutils-avr avr-libc \
    gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf picolibc-riscv64-unknown-elf \
    avrdude dfu-programmer dfu-util teensy-loader-cli \
    clang-format libusb-dev libhidapi-hidraw0 usbutils

  log "firmware: Rust"
  if have rustup; then
    echo "rustup already installed"
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi

  log "firmware: QMK CLI"
  uv tool install qmk
  echo "Next: run 'qmk setup' to clone the firmware repo"
fi

# ---------------------------------------------------------------------------
log "Done. Open a new terminal to load the new ~/.bashrc."
