#!/usr/bin/env bash
set -euo pipefail
echo "=== Stream preflight ==="
echo "-- Audio --"
pactl info 2>/dev/null | head -20 || wpctl status 2>/dev/null | head -40 || echo "no pulse/pipewire ctl"
echo "-- OBS --"
pgrep -a obs || echo "OBS not running"
echo "-- Disk --"
df -h "$HOME" | tail -1
