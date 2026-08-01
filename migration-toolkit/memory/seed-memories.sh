#!/usr/bin/env bash
set -euo pipefail
SRC="${RECALLD_DATA:-$HOME/.local/share/recalld}"
mkdir -p "$SRC/seed"
cat > "$SRC/seed/migration-context.md" <<EOF
# Migration context
- User: Adam Scerra
- Migrating Fedora laptop home via rsync staging at ~/migration-incoming/home-mirror
- Prefer network pull (new-laptop-pull-all.sh); USB fallback available
- Do not treat dry-runs as completed transfers
EOF
echo "Seeded $SRC/seed/migration-context.md"
