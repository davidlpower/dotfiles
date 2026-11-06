#!/usr/bin/env bash
# Dev-box inventory (Debian/Ubuntu). Read-only: writes a report to ~/dev-inventory.txt
out="$HOME/dev-inventory.txt"

section() { printf '\n=== %s ===\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

{
  echo "Generated: $(date -I)   Host: $(hostname)   OS: $(. /etc/os-release; echo "$PRETTY_NAME")"

  section "APT: install/remove commands you ran (oldest first)"
  zcat -f $(ls -tr /var/log/apt/history.log* 2>/dev/null) 2>/dev/null \
    | grep "Commandline:" | grep -Ei 'install|remove'

  section "APT: manually installed packages (minus base system)"
  if [ -f /var/log/installer/initial-status.gz ]; then
    comm -23 <(apt-mark showmanual | sort) \
             <(zcat /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort)
  else
    apt-mark showmanual
  fi

  section "APT: extra repositories"
  ls /etc/apt/sources.list.d 2>/dev/null

  section "Tool versions"
  for c in python3 pip3 uv pipx git gh node npm cargo rustc docker code ruff pytest mypy poetry pyenv make gcc; do
    have "$c" && printf '%-8s %s\n' "$c" "$("$c" --version 2>&1 | head -1)"
  done

  section "uv: tools"
  have uv && uv tool list

  section "uv: Python versions"
  have uv && uv python list --only-installed

  section "pipx"
  have pipx && pipx list --short

  section "cargo install"
  have cargo && cargo install --list | grep -v '^ '

  section "npm global"
  have npm && npm ls -g --depth=0 2>/dev/null

  section "snap"
  have snap && snap list

  section "flatpak"
  have flatpak && flatpak list --app

  section "~/.local/bin"
  ls ~/.local/bin 2>/dev/null

  section "~/.cargo/bin"
  ls ~/.cargo/bin 2>/dev/null

  section "/opt and /usr/local/bin"
  ls /opt /usr/local/bin 2>/dev/null

  section "Shell history: curl|sh style installers"
  grep -E '(curl|wget) .*\| *(sudo )?(ba)?sh' ~/.bash_history 2>/dev/null
} > "$out" 2>&1

echo "Wrote $out ($(wc -l < "$out") lines)"