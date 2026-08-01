#!/usr/bin/env bash
# Import a home-mirror tree into $HOME (run on NEW laptop).
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDES="${RSYNC_EXCLUDES:-$TOOLKIT_DIR/rsync-excludes.txt}"
FORCE_EMPTY=0
DRY_RUN=0
SRC=""

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--force-empty] <home-mirror-dir>

Example:
  $0 ~/migration-incoming/home-mirror

Refuses nearly-empty sources unless --force-empty is set.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force-empty) FORCE_EMPTY=1; shift ;;
    *)
      if [[ -n "$SRC" ]]; then
        echo "ERROR: unexpected arg: $1" >&2
        usage
        exit 1
      fi
      SRC="$1"
      shift
      ;;
  esac
done

if [[ -z "$SRC" ]]; then
  usage
  exit 1
fi

# Normalize trailing slash semantics for rsync
SRC_PATH="$(readlink -f "$SRC")"
if [[ ! -d "$SRC_PATH" ]]; then
  echo "ERROR: source is not a directory: $SRC" >&2
  exit 1
fi

FILE_COUNT="$(find "$SRC_PATH" -xdev -type f 2>/dev/null | wc -l | tr -d ' ')"
SIZE_K="$(du -sk "$SRC_PATH" 2>/dev/null | awk '{print $1}')"
SIZE_H="$(du -sh "$SRC_PATH" 2>/dev/null | awk '{print $1}')"

echo "=== Fedora Home Import ==="
echo "Source: $SRC_PATH/"
echo "Dest:   $HOME/"
echo "Size:   $SIZE_H ($FILE_COUNT files)"
echo

if [[ "$FILE_COUNT" -lt 20 || "$SIZE_K" -lt 10240 ]]; then
  echo "ERROR: source looks EMPTY ($FILE_COUNT files / ${SIZE_K}K)." >&2
  echo "This is the failure mode from the empty home-mirror import." >&2
  echo "Pull data first: OLD_HOST=user@old ./new-laptop-pull-all.sh" >&2
  echo "Or pass --force-empty to override (not recommended)." >&2
  if [[ "$FORCE_EMPTY" != "1" ]]; then
    exit 3
  fi
  echo "WARNING: continuing due to --force-empty"
fi

if [[ ! -f "$EXCLUDES" ]]; then
  echo "ERROR: excludes missing: $EXCLUDES" >&2
  exit 1
fi

echo "Dry run..."
rsync -aHAX --dry-run --info=stats2 --exclude-from="$EXCLUDES" "$SRC_PATH/" "$HOME/"
echo

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry-run only; not importing."
  exit 0
fi

read -r -p "Proceed with real import? [y/N] " ans
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

set +e
rsync -aHAX --info=progress2 --human-readable --partial \
  --exclude-from="$EXCLUDES" \
  "$SRC_PATH/" "$HOME/"
RC=$?
set -e

echo
if [[ "$RC" -eq 23 ]]; then
  echo "Import finished with rsync code 23 (some files/attrs skipped)."
elif [[ "$RC" -ne 0 ]]; then
  echo "ERROR: import rsync failed: $RC" >&2
  exit "$RC"
fi

echo "=== Import complete ==="
echo "Run: ./05-verify-migration.sh"
echo "Then: ./06-new-pc-ai-setup.sh"
