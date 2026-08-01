#!/usr/bin/env bash
# Diagnose migration state on the NEW laptop.
set -euo pipefail

MIRROR="${MIRROR_DIR:-$HOME/migration-incoming/home-mirror}"
TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Migration Diagnose ==="
echo "Host:     $(hostname) / $(whoami)"
echo "Date:     $(date -Is)"
echo "Toolkit:  $TOOLKIT_DIR"
echo "Mirror:   $MIRROR"
echo

echo "-- Disk --"
df -h "$HOME" / 2>/dev/null || df -h
echo

echo "-- Home top-level --"
ls -la "$HOME" | sed -n '1,40p'
echo

if [[ ! -d "$MIRROR" ]]; then
  echo "STATUS: NO_MIRROR"
  echo "  $MIRROR does not exist."
  echo "  Next: run ./new-laptop-pull-all.sh (network) or ./03-import-usb.sh (USB)."
  exit 2
fi

FILE_COUNT="$(find "$MIRROR" -xdev -type f 2>/dev/null | wc -l | tr -d ' ')"
DIR_COUNT="$(find "$MIRROR" -xdev -type d 2>/dev/null | wc -l | tr -d ' ')"
SIZE_H="$(du -sh "$MIRROR" 2>/dev/null | awk '{print $1}')"
SIZE_K="$(du -sk "$MIRROR" 2>/dev/null | awk '{print $1}')"

echo "-- Mirror stats --"
echo "  files: $FILE_COUNT"
echo "  dirs:  $DIR_COUNT"
echo "  size:  $SIZE_H (${SIZE_K}K)"
echo
echo "-- Mirror sample (depth 2) --"
find "$MIRROR" -maxdepth 2 -mindepth 1 2>/dev/null | head -40 || true
echo

# Heuristic: empty or nearly empty
if [[ "$FILE_COUNT" -lt 20 ]] || [[ "$SIZE_K" -lt 10240 ]]; then
  echo "STATUS: EMPTY_MIRROR"
  echo "  Importing now would copy almost nothing (this is your current stuck state)."
  echo "  Next:"
  echo "    1) Ensure old laptop is reachable: ssh \"\$OLD_HOST\" 'hostname; df -h ~'"
  echo "    2) Run REAL pull: OLD_HOST=user@ip ./new-laptop-pull-all.sh"
  echo "    3) Re-run this diagnose until STATUS is READY_TO_IMPORT"
  exit 3
fi

echo "STATUS: READY_TO_IMPORT"
echo "  Mirror looks populated. Safe to run:"
echo "    ./03-import-home.sh \"$MIRROR\""
exit 0
