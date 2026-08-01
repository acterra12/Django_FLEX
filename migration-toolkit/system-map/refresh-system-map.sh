#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_MD="$DIR/SYSTEM-MAP.md"
OUT_JSON="$DIR/system-map.json"

HOST="$(hostname)"
USER_NAME="$(whoami)"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
HOME_SIZE="$(du -sh "$HOME" 2>/dev/null | awk '{print $1}')"

{
  echo "# System map"
  echo
  echo "- Generated: $(date -Is)"
  echo "- Host: $HOST"
  echo "- User: $USER_NAME"
  echo "- IP: $IP"
  echo "- Home size: $HOME_SIZE"
  echo
  echo "## Disk"
  echo '```'
  df -h
  echo '```'
  echo
  echo "## Top home entries"
  echo '```'
  du -sh "$HOME"/* "$HOME"/.[^.]* 2>/dev/null | sort -h | tail -40 || true
  echo '```'
} > "$OUT_MD"

cat > "$OUT_JSON" <<EOF
{
  "generated": "$(date -Is)",
  "host": "$HOST",
  "user": "$USER_NAME",
  "ip": "$IP",
  "home_size": "$HOME_SIZE"
}
EOF

echo "Updated $OUT_MD and $OUT_JSON"
