#!/usr/bin/env bash
# Restore dconf/GNOME desktop snapshot if present.
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="${1:-$TOOLKIT_DIR/desktop-snapshot}"

echo "=== Restore desktop ==="

if [[ -f "$SNAP/dconf-user.ini" ]]; then
  echo "Loading dconf from $SNAP/dconf-user.ini"
  dconf load / < "$SNAP/dconf-user.ini"
else
  echo "No dconf-user.ini at $SNAP — skip (run 00-export-desktop-snapshot.sh on OLD first)"
fi

if [[ -f "$TOOLKIT_DIR/desktop-manifest.txt" ]]; then
  echo "Desktop manifest paths:"
  cat "$TOOLKIT_DIR/desktop-manifest.txt"
fi

echo "Optional: ./restore-gnome-extensions.sh"
echo "Then log out/in."
