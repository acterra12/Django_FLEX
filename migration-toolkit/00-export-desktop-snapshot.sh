#!/usr/bin/env bash
# Capture dconf + key desktop paths on OLD laptop.
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$TOOLKIT_DIR/desktop-snapshot}"
mkdir -p "$OUT"

echo "=== Desktop snapshot → $OUT ==="
dconf dump / > "$OUT/dconf-user.ini"
gnome-extensions list --enabled > "$OUT/gnome-extensions-enabled.txt" 2>/dev/null || true
gnome-extensions list > "$OUT/gnome-extensions-all.txt" 2>/dev/null || true

{
  echo "# Relative to \$HOME — review before restore"
  echo ".local/share/gnome-shell/extensions"
  echo ".config/autostart"
  echo ".fonts"
  echo ".local/share/fonts"
} > "$TOOLKIT_DIR/desktop-manifest.txt"

echo "Wrote $OUT and desktop-manifest.txt"
