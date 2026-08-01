#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-status}"
case "$cmd" in
  start) nohup obs >/tmp/obs.log 2>&1 & echo "started pid $!" ;;
  stop) pkill obs && echo stopped || echo "OBS not running" ;;
  status) pgrep -a obs || echo "OBS not running" ;;
  *) echo "Usage: $0 start|stop|status" >&2; exit 1 ;;
esac
