#!/usr/bin/env bash
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="${1:-$TOOLKIT_DIR/desktop-snapshot/gnome-extensions-enabled.txt}"

echo "=== Restore GNOME extensions ==="
echo "See also: $TOOLKIT_DIR/GNOME-EXTENSIONS.md"

if [[ ! -f "$LIST" ]]; then
  echo "No enabled-extensions list at $LIST"
  echo "Extensions dirs may still have been rsync'd under ~/.local/share/gnome-shell/extensions"
  exit 0
fi

while IFS= read -r ext || [[ -n "$ext" ]]; do
  [[ -z "$ext" ]] && continue
  echo "Enable: $ext"
  gnome-extensions enable "$ext" 2>/dev/null || echo "  (could not enable $ext — install manually)"
done < "$LIST"

echo "Restart GNOME Shell (Xorg: Alt+F2 r) or log out/in (Wayland)."
