#!/usr/bin/env bash
# Diagnose Input Leap client SSL / secure-socket failures on Linux (Fedora).
set -euo pipefail

echo "=== Input Leap client diagnose ==="
echo "Host: $(hostname)  User: $(whoami)  Date: $(date -Iseconds)"
echo

find_ssl_roots() {
  local candidates=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/input-leap/SSL"
    "${XDG_DATA_HOME:-$HOME/.local/share}/InputLeap/SSL"
    "$HOME/.local/share/input-leap/SSL"
    "$HOME/.local/share/InputLeap/SSL"
    "$HOME/.config/input-leap/SSL"
    "$HOME/.config/InputLeap/SSL"
  )
  local d
  for d in "${candidates[@]}"; do
    [[ -d "$d" ]] && printf '%s\n' "$d"
  done
  # Also surface Barrier leftovers that confuse migrations.
  for d in "$HOME/.local/share/barrier/SSL" "$HOME/.local/share/Barrier/SSL"; do
    [[ -d "$d" ]] && printf '%s\n' "$d (legacy barrier)"
  done
}

echo "-- Processes --"
if ps -ax -o user,pid,command 2>/dev/null | grep -E '[i]nput-leap|[b]arrier' || true; then
  :
fi
pgrep -a -f 'input-leap|barrier' 2>/dev/null || echo "(no input-leap/barrier processes)"
echo

echo "-- Binaries --"
for b in input-leap input-leapc input-leaps barrier barrierc barriers openssl; do
  if command -v "$b" >/dev/null 2>&1; then
    echo "  $b -> $(command -v "$b")"
  fi
done
rpm -q input-leap 2>/dev/null || true
flatpak list 2>/dev/null | grep -i leap || true
echo

echo "-- SSL directories --"
mapfile -t SSL_ROOTS < <(find_ssl_roots || true)
if [[ ${#SSL_ROOTS[@]} -eq 0 ]]; then
  echo "  NONE FOUND — this is a common cause of 'failed to connect to secure socket'"
  echo "  Expected: ~/.local/share/input-leap/SSL/Input Leap.pem"
else
  printf '  %s\n' "${SSL_ROOTS[@]}"
fi
echo

check_tree() {
  local root="$1"
  # strip legacy annotation
  root="${root%% (*}"
  echo "-- Tree: $root --"
  ls -la "$root" 2>/dev/null || true
  ls -la "$root/Fingerprints" 2>/dev/null || echo "  (no Fingerprints/)"
  local pem="$root/Input Leap.pem"
  [[ -f "$pem" ]] || pem="$root/InputLeap.pem"
  [[ -f "$pem" ]] || pem="$root/Barrier.pem"
  if [[ -f "$pem" ]]; then
    echo "  PEM: $pem"
    openssl x509 -in "$pem" -noout -subject -dates -fingerprint -sha256 2>/dev/null || \
      echo "  WARN: cannot parse PEM with openssl"
  else
    echo "  MISSING PEM (Input Leap.pem) — SSL cannot start"
  fi
  for f in Local.txt TrustedServers.txt TrustedClients.txt; do
    local path="$root/Fingerprints/$f"
    if [[ -f "$path" ]]; then
      echo "  $f:"
      sed 's/^/    /' "$path"
    else
      echo "  missing $f"
    fi
  done
  echo
}

if [[ ${#SSL_ROOTS[@]} -gt 0 ]]; then
  for root in "${SSL_ROOTS[@]}"; do
    check_tree "$root"
  done
fi

echo "-- Config snippets (server hostname / crypto) --"
for cfg in \
  "$HOME/.config/input-leap/InputLeap.conf" \
  "$HOME/.config/InputLeap/InputLeap.conf" \
  "$HOME/.config/Debauchee/InputLeap.conf" \
  "$HOME/.config/input-leap.conf"
do
  if [[ -f "$cfg" ]]; then
    echo "  file: $cfg"
    grep -E -i 'server|host|crypto|ssl|name|screen' "$cfg" 2>/dev/null | sed 's/^/    /' || true
  fi
done
# Qt / QSettings often under this path:
find "$HOME/.config" -iname '*input*leap*' -o -iname '*barrier*' 2>/dev/null | head -40 | sed 's/^/  /'
echo

if [[ -n "${SERVER_IP:-}" ]]; then
  echo "-- Reachability SERVER_IP=$SERVER_IP:24800 --"
  if timeout 3 bash -c "echo >/dev/tcp/${SERVER_IP}/24800" 2>/dev/null; then
    echo "  TCP open"
    echo | timeout 5 openssl s_client -connect "${SERVER_IP}:24800" 2>/dev/null | \
      head -n 25 | sed 's/^/  /' || echo "  openssl handshake failed/incomplete"
  else
    echo "  TCP CLOSED/REFUSED — fix network/firewall/server-listen before SSL trust"
  fi
else
  echo "-- Reachability --"
  echo "  Set SERVER_IP=x.x.x.x and re-run to test port 24800"
fi

echo
echo "=== Diagnose complete ==="
echo "Next: export SERVER_HOST=user@server and SERVER_IP=x.x.x.x then run ./02-fix-secure-socket.sh"
