#!/usr/bin/env bash
set -euo pipefail
TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  if [[ -e "$HOME/$line" ]]; then
    echo "OK   ~/$line"
  else
    echo "MISS ~/$line"
    FAIL=1
  fi
done < "$TOOLKIT_DIR/projects-manifest.txt"
exit "$FAIL"
