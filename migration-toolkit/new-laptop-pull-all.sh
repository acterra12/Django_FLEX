#!/usr/bin/env bash
# Pull old laptop $HOME into ~/migration-incoming/home-mirror (run on NEW laptop).
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_HOST="${OLD_HOST:-}"
DEST="${DEST_DIR:-$HOME/migration-incoming/home-mirror}"
EXCLUDES="${RSYNC_EXCLUDES:-$TOOLKIT_DIR/rsync-excludes.txt}"
DRY_RUN="${DRY_RUN:-0}"
SSH_OPTS="${SSH_OPTS:--o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 -o ServerAliveCountMax=4}"

usage() {
  cat <<EOF
Usage: OLD_HOST=user@old-host $0 [--dry-run]

Pulls remote \\\$HOME/ into: $DEST

Env:
  OLD_HOST          required (user@host or user@ip)
  DEST_DIR          default: ~/migration-incoming/home-mirror
  RSYNC_EXCLUDES    default: ./rsync-excludes.txt
  DRY_RUN=1         plan only (also --dry-run)
  SSH_OPTS          extra ssh options
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --dry-run) DRY_RUN=1 ;;
    *) echo "Unknown arg: $arg" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$OLD_HOST" ]]; then
  echo "ERROR: set OLD_HOST=user@old-laptop" >&2
  usage
  exit 1
fi

if [[ ! -f "$EXCLUDES" ]]; then
  echo "ERROR: excludes file missing: $EXCLUDES" >&2
  exit 1
fi

mkdir -p "$DEST"

echo "=== New laptop pull-all ==="
echo "Source: ${OLD_HOST}:\$HOME/"
echo "Dest:   $DEST/"
echo "Excl:   $EXCLUDES"
echo "Mode:   $([[ "$DRY_RUN" == "1" ]] && echo DRY-RUN || echo REAL TRANSFER)"
echo

echo "-- Connectivity check --"
if ! ssh $SSH_OPTS "$OLD_HOST" 'echo OK; hostname; whoami; df -h "$HOME" | tail -1; du -sh "$HOME" 2>/dev/null | head -1'; then
  echo "ERROR: cannot SSH to $OLD_HOST" >&2
  echo "On the OLD laptop run: ./old-laptop-prep-ssh.sh" >&2
  exit 1
fi
REMOTE_HOME=$(ssh $SSH_OPTS "$OLD_HOST" "printf %s \"\$HOME\"")
if [[ -z "$REMOTE_HOME" || "$REMOTE_HOME" != /* ]]; then
  echo "ERROR: could not resolve remote HOME (got: $REMOTE_HOME)" >&2
  exit 1
fi
echo "Remote HOME: $REMOTE_HOME"
echo

RSYNC_FLAGS=(-aHAX --info=progress2 --human-readable --partial --append-verify
  --exclude-from="$EXCLUDES"
  -e "ssh $SSH_OPTS")

if [[ "$DRY_RUN" == "1" ]]; then
  RSYNC_FLAGS+=(--dry-run)
fi

set +e
rsync "${RSYNC_FLAGS[@]}" "${OLD_HOST}:${REMOTE_HOME}/" "$DEST/"
RC=$?
set -e

echo
echo "rsync exit: $RC"
if [[ "$RC" -eq 23 ]]; then
  echo "NOTE: code 23 = some files/attrs skipped (perms, vanished files, xattrs)."
  echo "      Often OK for home migration; review stderr above, then re-run to retry."
elif [[ "$RC" -ne 0 ]]; then
  echo "ERROR: rsync failed with code $RC" >&2
  exit "$RC"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo
  echo "DRY RUN complete — NOTHING was copied."
  echo "Re-run without --dry-run / DRY_RUN=1 to transfer for real."
  exit 0
fi

echo
echo "-- Post-transfer size --"
du -sh "$DEST"
find "$DEST" -xdev -type f | wc -l | awk '{print "files:", $1}'
echo
echo "Next: ./00-diagnose.sh && ./03-import-home.sh \"$DEST\""
