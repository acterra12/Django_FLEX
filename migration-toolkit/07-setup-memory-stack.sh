#!/usr/bin/env bash
# Optional recalld / Obsidian memory stack on NEW laptop.
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEM="$TOOLKIT_DIR/memory"

echo "=== Memory stack setup ==="
echo "See: $MEM/MEMORY-ARCHITECTURE.md"

mkdir -p "$HOME/.config/recalld" "$HOME/.local/share/recalld" "$HOME/.local/bin"

if [[ -f "$MEM/recalld-config.toml.template" ]]; then
  if [[ ! -f "$HOME/.config/recalld/config.toml" ]]; then
    sed "s|__HOME__|$HOME|g" "$MEM/recalld-config.toml.template" > "$HOME/.config/recalld/config.toml"
    echo "Wrote ~/.config/recalld/config.toml"
  else
    echo "Keeping existing ~/.config/recalld/config.toml"
  fi
fi

for unit in recalld.service memory-obsidian-sync.service memory-obsidian-sync.timer; do
  if [[ -f "$MEM/$unit" ]]; then
    install -m 644 "$MEM/$unit" "$HOME/.config/systemd/user/$unit" 2>/dev/null || {
      mkdir -p "$HOME/.config/systemd/user"
      install -m 644 "$MEM/$unit" "$HOME/.config/systemd/user/$unit"
    }
  fi
done

if [[ -f "$MEM/sync-recalld-to-obsidian.sh" ]]; then
  install -m 755 "$MEM/sync-recalld-to-obsidian.sh" "$HOME/.local/bin/sync-recalld-to-obsidian.sh"
fi
if [[ -f "$MEM/cursor-memory-hook.sh" ]]; then
  install -m 755 "$MEM/cursor-memory-hook.sh" "$HOME/.local/bin/cursor-memory-hook.sh"
fi

systemctl --user daemon-reload || true
echo
echo "Enable when recalld binary is installed:"
echo "  systemctl --user enable --now recalld.service"
echo "  systemctl --user enable --now memory-obsidian-sync.timer"
echo
echo "Seed helper: $MEM/seed-memories.sh"
echo "AGENTS snippet: $MEM/AGENTS-memory-section.md"
