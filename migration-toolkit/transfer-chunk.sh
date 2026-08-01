#!/usr/bin/env bash
# Transfer a single relative path from OLD_HOST into the mirror (resume-friendly).
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_HOST="${OLD_HOST:-}"
REL="${1:-}"
DEST_ROOT="${DEST_DIR:-$HOME/migration-incoming/home-mirror}"
SSH_OPTS="${SSH_OPTS:--o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30}"

if [[ -z "$OLD_HOST" || -z "$REL" ]]; then
  echo "Usage: OLD_HOST=user@old $0 <relative-path-under-home>" >&2
  echo "Example: OLD_HOST=adam@192.168.1.10 $0 development" >&2
  exit 1
fi

REL="${REL#/}"
REMOTE_HOME=$(ssh $SSH_OPTS "$OLD_HOST" "printf %s \"\$HOME\"")
mkdir -p "$DEST_ROOT/$(dirname "$REL")"

echo "Chunk: ${OLD_HOST}:${REMOTE_HOME}/$REL → $DEST_ROOT/$REL"
rsync -aHAX --info=progress2 --human-readable --partial --append-verify \
  -e "ssh $SSH_OPTS" \
  "${OLD_HOST}:${REMOTE_HOME}/$REL" "$DEST_ROOT/$(dirname "$REL")/"
