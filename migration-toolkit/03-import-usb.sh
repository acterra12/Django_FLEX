#!/usr/bin/env bash
# Import from USB home-mirror into staging or directly into $HOME.
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="${1:-}"
STAGE="${STAGE_DIR:-$HOME/migration-incoming/home-mirror}"

if [[ -z "$USB_ROOT" ]]; then
  echo "Usage: $0 /run/media/\$USER/USB_LABEL" >&2
  exit 1
fi

SRC=""
if [[ -d "$USB_ROOT/home-mirror" ]]; then
  SRC="$USB_ROOT/home-mirror"
elif [[ -d "$USB_ROOT" ]] && [[ -e "$USB_ROOT/.bashrc" || -d "$USB_ROOT/Documents" || -d "$USB_ROOT/development" ]]; then
  SRC="$USB_ROOT"
else
  echo "ERROR: could not find home-mirror under $USB_ROOT" >&2
  exit 1
fi

echo "=== USB import → staging ==="
echo "USB source: $SRC"
echo "Staging:    $STAGE"
mkdir -p "$STAGE"

set +e
rsync -aHAX --info=progress2 --human-readable --partial "$SRC/" "$STAGE/"
RC=$?
set -e
echo "rsync exit: $RC"

"$TOOLKIT_DIR/00-diagnose.sh" || true
echo
echo "If STATUS is READY_TO_IMPORT:"
echo "  ./03-import-home.sh \"$STAGE\""
