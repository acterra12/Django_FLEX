#!/usr/bin/env bash
set -euo pipefail
VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/Obsidian/Memory}"
SRC="${RECALLD_DATA:-$HOME/.local/share/recalld}"
mkdir -p "$VAULT"
OUT="$VAULT/recalld-sync.md"
{
  echo "# recalld sync $(date -Is)"
  echo
  if [[ -d "$SRC" ]]; then
    find "$SRC" -type f -name '*.md' -o -name '*.jsonl' 2>/dev/null | head -200 | while read -r f; do
      echo "## $(basename "$f")"
      echo
      sed -n '1,80p' "$f"
      echo
    done
  else
    echo "_No recalld data at $SRC_"
  fi
} > "$OUT"
echo "Wrote $OUT"
