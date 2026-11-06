#!/usr/bin/env bash
# Removes leftovers from the earlier manual setup. Safe to re-run.
#
# Usage:  ./cleanup.sh             do the cleanup
#         ./cleanup.sh --dry-run   show what would change, touch nothing
#
# Removes lines in ~/.profile that point at another user's home directory,
# e.g. export PATH="$PATH:/home/david/.local/bin" when logged in as a different user.
# A timestamped backup of ~/.profile is made first.
set -euo pipefail

DRY_RUN=0
case "${1:-}" in
  "")        ;;
  --dry-run) DRY_RUN=1 ;;
  -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
  *)         echo "Unknown option: $1" >&2; exit 1 ;;
esac

log() { printf '\n==> %s\n' "$*"; }
[ "$DRY_RUN" -eq 1 ] && echo "(dry run: nothing will be changed)"

# ---------------------------------------------------------------------------
log "Stale other-user lines in ~/.profile"
profile="$HOME/.profile"
me="$(id -un)"

# awk program: print lines mentioning /home/<someone other than me>/
stale_lines() {
  awk -v me="$me" '
    match($0, /\/home\/[^\/ \t"]+\//) {
      user = substr($0, RSTART + 6, RLENGTH - 7)
      if (user != me) printf "line %d: %s\n", NR, $0
    }' "$profile"
}

if [ ! -f "$profile" ]; then
  echo "none:   $profile not found"
else
  stale="$(stale_lines)"
  if [ -z "$stale" ]; then
    echo "none:   no lines pointing at another user's home"
  else
    echo "$stale"
    if [ "$DRY_RUN" -eq 0 ]; then
      backup="$profile.bak.$(date +%Y%m%d-%H%M%S)"
      cp "$profile" "$backup"
      echo "backup: $backup"

      tmp="$(mktemp)"
      awk -v me="$me" '
        match($0, /\/home\/[^\/ \t"]+\//) {
          user = substr($0, RSTART + 6, RLENGTH - 7)
          if (user != me) next
        }
        { print }' "$profile" > "$tmp"
      cat "$tmp" > "$profile"   # keeps the original file permissions
      rm -f "$tmp"
      echo "removed the lines above"
    fi
  fi
fi

log "Done."
[ "$DRY_RUN" -eq 1 ] && echo "Run again without --dry-run to apply."
exit 0