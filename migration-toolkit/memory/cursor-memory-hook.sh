#!/usr/bin/env bash
# Print recent memory snippets for pasting into an agent prompt.
set -euo pipefail
SRC="${RECALLD_DATA:-$HOME/.local/share/recalld}"
echo "=== Recent memories ($(date -Is)) ==="
if [[ -d "$SRC" ]]; then
  find "$SRC" -type f \( -name '*.md' -o -name '*.txt' \) -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr | head -10 | while read -r _ p; do
      echo "--- $p ---"
      sed -n '1,40p' "$p"
      echo
    done
else
  echo "No recalld data yet."
fi
