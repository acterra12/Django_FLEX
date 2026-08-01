#!/usr/bin/env bash
# Prepare OLD laptop for network pull (run on OLD laptop).
set -euo pipefail

echo "=== Old laptop SSH prep ==="

if ! command -v sshd >/dev/null 2>&1 && ! systemctl list-unit-files | grep -q sshd; then
  echo "Installing openssh-server..."
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y openssh-server
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y openssh-server
  else
    echo "ERROR: install openssh-server manually" >&2
    exit 1
  fi
fi

sudo systemctl enable --now sshd 2>/dev/null || sudo systemctl enable --now ssh

if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
  sudo firewall-cmd --add-service=ssh --permanent || true
  sudo firewall-cmd --reload || true
fi

IP_LIST="$(hostname -I 2>/dev/null || true)"
echo
echo "SSH is listening. From the NEW laptop:"
echo "  export OLD_HOST=$(whoami)@<one-of: $IP_LIST>"
echo "  ssh \"\$OLD_HOST\" 'hostname'"
echo "  ./new-laptop-pull-all.sh"
echo
ss -ltnp 2>/dev/null | grep -E ':22\\b' || sudo ss -ltnp | grep -E ':22\\b' || true
