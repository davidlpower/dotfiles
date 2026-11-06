# dotfiles

Shell and dev-environment setup for my WSL Ubuntu machines.

Last verified: 2026-11-06 on Ubuntu 24.04 and Ubuntu 26.04, both under WSL.

## Quick start (new machine)

```bash
git clone <repo-url> ~/projects/dotfiles
cd ~/projects/dotfiles
./setup.sh              # core Python dev setup
./setup.sh --firmware   # same, plus QMK keyboard firmware tooling
```

Then open a new terminal. Run `claude` once to sign in.

## Files

| File | Purpose |
| --- | --- |
| `bashrc` | Shared `~/.bashrc` (prompt, history, PATH, git prompt, fzf) |
| `setup.sh` | Installs everything and copies `bashrc` into place. Safe to re-run |
| `cleanup.sh` | Removes old leftovers (see below). `--dry-run` previews |
| `dev-inventory.sh` | Read-only report of what is installed, written to `~/dev-inventory.txt` |

## What `setup.sh` installs

- **apt:** `build-essential git curl make htop fzf bat fd-find bind9-dnsutils`
- **`bat` / `fd` commands:** symlinks in `~/.local/bin` pointing at `batcat` / `fdfind`, so I can type `bat` and `fd`
- **uv**, if missing (standalone installer, PATH handled by `bashrc`)
- **Pythons via uv:** 3.10, 3.14, 3.15
- **uv tools:** `ipython`
- **Claude Code CLI** (native installer, auto-updates itself)
- **`~/.bashrc`**, replaced with `bashrc` from this repo (old one backed up as `~/.bashrc.bak.<timestamp>`)

`--firmware` adds: ARM/AVR/RISC-V compilers, flashing tools (`avrdude`, `dfu-util`, ...), Rust (rustup), and the `qmk` CLI via `uv tool install`.

## Changing things

1. Edit `bashrc` **in this repo**, not `~/.bashrc` (setup overwrites that).
2. Commit and push.
3. On each machine: `git pull && ./setup.sh`.

Settings that only one machine needs go in `~/.bashrc.local` (not in git). The shared `bashrc` loads it last, so it can override anything.

## Checking that machines match

Run `./dev-inventory.sh` on each machine, then compare the two `~/dev-inventory.txt` files.
Expected differences: OS version, system Python, `gcc`/`git`/`make` versions, and the firmware tooling.

## Cleanup of old leftovers

Only needed on machines set up before these scripts existed.

```bash
./cleanup.sh --dry-run   # preview
./cleanup.sh
```

- Removes lines in `~/.profile` that point at another user's home (e.g. `/home/david/.local/bin` when logged in as a different user). Backs up `~/.profile` first. A leftover `# Created by pipx` comment may need deleting by hand.

## Known gotchas

- **Ubuntu names:** `bat` is `batcat` and `fd` is `fdfind` on Debian/Ubuntu. `setup.sh` adds `bat`/`fd` symlinks for typing in a terminal and in scripts; `bashrc` detects whichever name exists for fzf, so fzf works either way.
- **Old fzf:** Ubuntu 24.04 ships fzf 0.44, which has no `fzf --bash`. `bashrc` falls back to the example key-binding files in `/usr/share/doc/fzf/examples/`.
- **Python patch versions drift:** `uv python install` skips a minor version that is already installed. To refresh: `uv self update`, then `uv python upgrade --preview` (the upgrade command is a preview feature in uv).
- **`qmk` installed earlier with pipx:** before using `--firmware` on such a machine, run `pipx uninstall qmk` so the two copies don't clash. Run `qmk setup` afterwards to clone the firmware repo.
- **`bootloadHID`** in `/usr/local/bin` was installed by hand on my firmware machine and is not covered by the scripts.

## Not covered

- SSH keys and any secrets (create per machine, never commit)
- `~/.gitconfig` and VS Code extensions
- Project dependencies (each project's `pyproject.toml` / `uv.lock`)
- `~/.pythonrc` / `PYTHONSTARTUP` (dropped on purpose)