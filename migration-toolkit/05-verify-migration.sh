#!/usr/bin/env bash
# Spot-check that critical paths landed on the NEW laptop.
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0

check_path() {
  local p="$1"
  if [[ -e "$HOME/$p" ]]; then
    echo "OK   ~/$p"
  else
    echo "MISS ~/$p"
    FAIL=1
  fi
}

echo "=== Verify migration ==="
echo "Host: $(hostname)  User: $(whoami)"
echo

echo "-- Disk --"
df -h "$HOME" | tail -1
echo "Home size: $(du -sh "$HOME" 2>/dev/null | awk '{print $1}')"
echo

echo "-- Manifest: projects --"
if [[ -f "$TOOLKIT_DIR/projects-manifest.txt" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    check_path "$line"
  done < "$TOOLKIT_DIR/projects-manifest.txt"
else
  echo "(no projects-manifest.txt)"
fi
echo

echo "-- Manifest: dotfiles --"
if [[ -f "$TOOLKIT_DIR/dotfiles-manifest.txt" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    check_path "$line"
  done < "$TOOLKIT_DIR/dotfiles-manifest.txt"
else
  for p in .gitconfig .ssh .bashrc .zshrc .config/Cursor .config/cursor; do
    check_path "$p"
  done
fi
echo

echo "-- SSH keys present? --"
if [[ -d "$HOME/.ssh" ]]; then
  ls -la "$HOME/.ssh" | head -30
  echo "Fix perms if needed: chmod 700 ~/.ssh && chmod 600 ~/.ssh/*"
else
  echo "MISS ~/.ssh"
  FAIL=1
fi
echo

if [[ "$FAIL" -eq 0 ]]; then
  echo "STATUS: VERIFY_OK"
else
  echo "STATUS: VERIFY_GAPS — review MISSing paths before wiping the old laptop"
  exit 1
fi
