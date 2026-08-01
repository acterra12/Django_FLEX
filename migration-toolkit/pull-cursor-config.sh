#!/usr/bin/env bash
# Pull Cursor config dirs only from OLD_HOST into the live home (or staging).
set -euo pipefail

OLD_HOST="${OLD_HOST:-}"
MODE="${1:-stage}" # stage|live
DEST_BASE="$HOME/migration-incoming/home-mirror"
SSH_OPTS="${SSH_OPTS:--o StrictHostKeyChecking=accept-new}"

if [[ -z "$OLD_HOST" ]]; then
  echo "Usage: OLD_HOST=user@old $0 [stage|live]" >&2
  exit 1
fi

if [[ "$MODE" == "live" ]]; then
  DEST_BASE="$HOME"
fi

REMOTE_HOME=$(ssh $SSH_OPTS "$OLD_HOST" "printf %s \"\$HOME\"")
paths=(.config/Cursor .config/cursor .cursor)
for p in "${paths[@]}"; do
  echo "Pulling $p..."
  mkdir -p "$DEST_BASE/$(dirname "$p")"
  rsync -aHAX --info=progress2 -e "ssh $SSH_OPTS" \
    "${OLD_HOST}:${REMOTE_HOME}/$p/" "$DEST_BASE/$p/" 2>/dev/null || echo "  skip $p (missing on old)"
done

echo "Done ($MODE)."
