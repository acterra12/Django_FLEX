#!/usr/bin/env bash
set -euo pipefail
TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$TOOLKIT_DIR/05-verify-migration.sh"
