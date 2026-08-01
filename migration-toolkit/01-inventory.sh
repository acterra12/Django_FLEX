#!/usr/bin/env bash
# Capture inventory of current machine (usually OLD laptop).
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${OUT_DIR:-$TOOLKIT_DIR/reports}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$OUT_DIR/inventory-$STAMP.txt"

mkdir -p "$OUT_DIR"

{
  echo "=== Inventory $STAMP ==="
  echo "host: $(hostname)"
  echo "user: $(whoami)"
  echo "home: $HOME"
  echo
  echo "-- uname --"
  uname -a
  echo
  echo "-- disk --"
  df -h
  echo
  echo "-- home size --"
  du -sh "$HOME" 2>/dev/null || true
  echo
  echo "-- top home dirs --"
  du -sh "$HOME"/* "$HOME"/.[^.]* 2>/dev/null | sort -h | tail -80 || true
  echo
  echo "-- git repos (depth <=4) --"
  find "$HOME" -maxdepth 4 -type d -name .git 2>/dev/null | sed 's|/.git$||' | head -200 || true
  echo
  echo "-- docker --"
  command -v docker >/dev/null && docker ps -a || echo "docker not available"
  echo
  echo "-- rpm/dnf user groups --"
  id
  echo
  echo "-- listening ports --"
  ss -ltnp 2>/dev/null | head -80 || true
} | tee "$OUT"

echo
echo "Wrote $OUT"
