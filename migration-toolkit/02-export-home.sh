#!/usr/bin/env bash
# Export $HOME to a local/network destination directory as home-mirror content.
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDES="${RSYNC_EXCLUDES:-$TOOLKIT_DIR/rsync-excludes.txt}"
DEST="${1:-}"

if [[ -z "$DEST" ]]; then
  echo "Usage: $0 /path/to/destination-dir" >&2
  echo "Writes into DEST/home-mirror/" >&2
  exit 1
fi

mkdir -p "$DEST/home-mirror"
echo "=== Home export ==="
echo "Source: $HOME/"
echo "Dest:   $DEST/home-mirror/"

rsync -aHAX --info=progress2 --human-readable --partial \
  --exclude-from="$EXCLUDES" \
  "$HOME/" "$DEST/home-mirror/"

du -sh "$DEST/home-mirror"
echo "Done."
