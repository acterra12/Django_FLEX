#!/usr/bin/env bash
# Export $HOME to a USB stick as home-mirror/ (run on OLD laptop).
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDES="${RSYNC_EXCLUDES:-$TOOLKIT_DIR/rsync-usb-excludes.txt}"
USB_ROOT="${1:-}"

if [[ -z "$USB_ROOT" ]]; then
  echo "Usage: $0 /run/media/\$USER/USB_LABEL" >&2
  exit 1
fi

if [[ ! -d "$USB_ROOT" ]]; then
  echo "ERROR: USB path not found: $USB_ROOT" >&2
  exit 1
fi

DEST="$USB_ROOT/home-mirror"
mkdir -p "$DEST"

echo "=== USB export ==="
echo "Source: $HOME/"
echo "Dest:   $DEST/"
df -h "$USB_ROOT"
echo

read -r -p "Proceed with USB export? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo Aborted; exit 0; }

set +e
rsync -aHAX --info=progress2 --human-readable --partial \
  --exclude-from="$EXCLUDES" \
  "$HOME/" "$DEST/"
RC=$?
set -e

# Also copy toolkit itself onto USB for the new machine
mkdir -p "$USB_ROOT/transfer"
rsync -a --delete "$TOOLKIT_DIR/" "$USB_ROOT/transfer/" --exclude reports/inventory-* || true

echo
echo "rsync exit: $RC"
du -sh "$DEST"
echo "Next on NEW laptop: ./03-import-usb.sh \"$USB_ROOT\""
