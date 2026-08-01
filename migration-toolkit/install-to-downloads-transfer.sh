#!/usr/bin/env bash
# Copy this toolkit into ~/Downloads/transfer in the flat layout Adam already uses.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-$HOME/Downloads/transfer}"

mkdir -p "$DEST" "$DEST/reports"

rsync -a --delete \
  --exclude '.git/' \
  --exclude 'install-to-downloads-transfer.sh' \
  "$SRC/" "$DEST/"

# Flat convenience copies (match prior Downloads/transfer listing)
cp -a "$SRC/memory/"*.md "$DEST/" 2>/dev/null || true
cp -a "$SRC/memory/"*.sh "$DEST/" 2>/dev/null || true
cp -a "$SRC/memory/"*.service "$DEST/" 2>/dev/null || true
cp -a "$SRC/memory/"*.timer "$DEST/" 2>/dev/null || true
cp -a "$SRC/memory/"*.template "$DEST/" 2>/dev/null || true
cp -a "$SRC/system-map/"* "$DEST/" 2>/dev/null || true

chmod +x "$DEST"/*.sh "$DEST"/memory/*.sh "$DEST"/streaming/*.sh "$DEST"/system-map/*.sh 2>/dev/null || true

echo "Installed toolkit → $DEST"
echo "Next: cd \"$DEST\" && ./00-diagnose.sh"
