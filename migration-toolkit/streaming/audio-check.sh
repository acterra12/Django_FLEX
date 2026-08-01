#!/usr/bin/env bash
set -euo pipefail
echo "=== Sinks ==="
pactl list short sinks 2>/dev/null || true
echo "=== Sources ==="
pactl list short sources 2>/dev/null || true
