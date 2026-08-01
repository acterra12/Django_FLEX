#!/usr/bin/env bash
# Post-import setup for Cursor / Node / common AI CLI tools on NEW laptop.
set -euo pipefail

echo "=== New PC AI / dev setup ==="

if command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y git curl wget jq ripgrep fd-find tmux python3-pip || true
fi

# Node via nvm if missing
if [[ ! -d "$HOME/.nvm" ]] && [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
  echo "Installing nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# shellcheck disable=SC1091
[[ -s "$HOME/.nvm/nvm.sh" ]] && source "$HOME/.nvm/nvm.sh"
if command -v nvm >/dev/null 2>&1; then
  nvm install --lts || true
fi

echo
echo "Cursor config tips:"
echo "  - If ~/.config/Cursor (or Cursor dirs) came over, open Cursor once and sign in."
echo "  - Local agent chats do NOT sync across machines; cloud agent history is account-scoped."
echo "  - Optional: ./pull-cursor-config.sh if you staged Cursor config separately."
echo
echo "SSH agent:"
echo "  eval \"\$(ssh-agent -s)\""
echo "  ssh-add ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_rsa 2>/dev/null || true"
echo
echo "Done. Next optional: ./07-setup-memory-stack.sh"
