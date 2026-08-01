#!/usr/bin/env bash
# Fix Input Leap "failed to connect to secure socket" on a Linux client.
#
# Usage (on the NEW laptop / client):
#   export SERVER_IP=192.168.1.42
#   export SERVER_HOST=adam@192.168.1.42   # optional but preferred
#   ./02-fix-secure-socket.sh
#
# Optional:
#   SERVER_FINGERPRINT='v2:sha256:AA:BB:...'   # paste from server GUI / Local.txt
#   PROFILE_DIR=$HOME/.local/share/input-leap  # override data dir
#   OPEN_FIREWALL=1                            # default 1; set 0 to skip
set -euo pipefail

SERVER_IP="${SERVER_IP:-}"
SERVER_HOST="${SERVER_HOST:-}"
SERVER_FINGERPRINT="${SERVER_FINGERPRINT:-}"
OPEN_FIREWALL="${OPEN_FIREWALL:-1}"
PORT="${PORT:-24800}"

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*" >&2; }
ok() { echo "    OK: $*" >&2; }
warn() { echo "    WARN: $*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

need_cmd openssl
need_cmd mkdir

pick_profile_dir() {
  if [[ -n "${PROFILE_DIR:-}" ]]; then
    printf '%s\n' "$PROFILE_DIR"
    return
  fi
  local candidates=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/input-leap"
    "${XDG_DATA_HOME:-$HOME/.local/share}/InputLeap"
    "$HOME/.local/share/input-leap"
    "$HOME/.local/share/InputLeap"
  )
  local d
  for d in "${candidates[@]}"; do
    if [[ -d "$d/SSL" || -f "$d/SSL/Input Leap.pem" || -d "$d" ]]; then
      # Prefer lowercase path used by current Input Leap builds.
      if [[ -d "$d" ]]; then
        printf '%s\n' "$d"
        return
      fi
    fi
  done
  printf '%s\n' "$HOME/.local/share/input-leap"
}

PROFILE_DIR="$(pick_profile_dir)"
SSL_DIR="$PROFILE_DIR/SSL"
FP_DIR="$SSL_DIR/Fingerprints"
PEM="$SSL_DIR/Input Leap.pem"
LOCAL_FP="$FP_DIR/Local.txt"
TRUSTED_SERVERS="$FP_DIR/TrustedServers.txt"

info "Profile dir: $PROFILE_DIR"
mkdir -p "$FP_DIR"

# Stop conflicting clients so files are not rewritten mid-fix.
if pgrep -f 'input-leapc|input-leaps|barrierc|barriers' >/dev/null 2>&1; then
  warn "Input Leap/Barrier processes are running."
  warn "Stop the GUI (or: pkill -f 'input-leapc|input-leaps') then re-run if the fix does not stick."
fi

ensure_pem() {
  if [[ -f "$PEM" ]]; then
    ok "PEM exists: $PEM"
    return
  fi
  info "Generating self-signed PEM (was missing)"
  # Match Input Leap UI: CN=Input Leap, RSA 2048, sha256.
  openssl req -x509 -nodes -days 3650 -subj "/CN=Input Leap" \
    -newkey rsa:2048 -keyout "$PEM" -out "$PEM" >/dev/null 2>&1
  chmod 600 "$PEM"
  ok "Wrote $PEM"
}

write_local_fingerprint() {
  need_cmd openssl
  local fp
  fp="$(openssl x509 -fingerprint -sha256 -noout -in "$PEM" | sed 's/^.*=//')"
  [[ -n "$fp" ]] || die "could not compute fingerprint from PEM"
  # Input Leap v2 fingerprint format
  printf 'v2:sha256:%s\n' "$fp" >"$LOCAL_FP"
  ok "Local fingerprint -> $LOCAL_FP"
  sed 's/^/      /' "$LOCAL_FP" >&2
}

normalize_fp() {
  local raw="$1"
  raw="$(echo "$raw" | tr -d '\r' | head -n1 | xargs)"
  [[ -n "$raw" ]] || return 1
  if [[ "$raw" == v2:sha256:* ]]; then
    printf '%s\n' "$raw"
  elif [[ "$raw" == *:*:* ]]; then
    # bare AA:BB:...sha256 fingerprint
    printf 'v2:sha256:%s\n' "$raw"
  else
    printf '%s\n' "$raw"
  fi
}

fetch_server_fingerprint_via_ssh() {
  [[ -n "$SERVER_HOST" ]] || return 1
  info "Fetching server Local.txt via SSH ($SERVER_HOST)"
  local remote_paths=(
    '.local/share/input-leap/SSL/Fingerprints/Local.txt'
    '.local/share/InputLeap/SSL/Fingerprints/Local.txt'
    'Library/Application Support/input-leap/SSL/Fingerprints/Local.txt'
    'AppData/Local/Input Leap/SSL/Fingerprints/Local.txt'
  )
  local p out
  for p in "${remote_paths[@]}"; do
    if out="$(ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new \
      "$SERVER_HOST" "test -f \$HOME/$p && cat \$HOME/$p" 2>/dev/null)"; then
      if [[ -n "$out" ]]; then
        normalize_fp "$out"
        return 0
      fi
    fi
  done
  # Windows-style via powershell path often needs different home; try find.
  if out="$(ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new \
    "$SERVER_HOST" 'find "$HOME" -path "*input-leap*/SSL/Fingerprints/Local.txt" -o -path "*InputLeap*/SSL/Fingerprints/Local.txt" -o -path "*Input Leap*/SSL/Fingerprints/Local.txt" 2>/dev/null | head -1 | xargs -r cat' 2>/dev/null)"; then
    if [[ -n "$out" ]]; then
      normalize_fp "$out"
      return 0
    fi
  fi
  return 1
}

fetch_server_fingerprint_via_openssl() {
  local target_ip="$1"
  info "Fetching server cert fingerprint via openssl ($target_ip:$PORT)"
  local tmp fp
  tmp="$(mktemp)"
  # Input Leap speaks TLS on 24800; grab the peer cert.
  if ! echo | timeout 8 openssl s_client -connect "${target_ip}:${PORT}" -showcerts 2>/dev/null \
    | openssl x509 -fingerprint -sha256 -noout 2>/dev/null | sed 's/^.*=//' >"$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  fp="$(tr -d '\r\n' <"$tmp")"
  rm -f "$tmp"
  [[ -n "$fp" ]] || return 1
  normalize_fp "$fp"
}

trust_server_fingerprint() {
  local fp="$1"
  fp="$(normalize_fp "$fp")" || die "empty server fingerprint"
  touch "$TRUSTED_SERVERS"
  if grep -Fxq "$fp" "$TRUSTED_SERVERS" 2>/dev/null; then
    ok "Already trusted: $fp"
  else
    info "Adding server fingerprint to TrustedServers.txt"
    printf '%s\n' "$fp" >>"$TRUSTED_SERVERS"
    ok "Trusted $fp"
  fi
  echo "    TrustedServers.txt:" >&2
  sed 's/^/      /' "$TRUSTED_SERVERS" >&2
}

test_tcp() {
  local ip="$1"
  if timeout 3 bash -c "echo >/dev/tcp/${ip}/${PORT}" 2>/dev/null; then
    ok "TCP ${ip}:${PORT} open"
    return 0
  fi
  warn "TCP ${ip}:${PORT} not reachable from this machine"
  return 1
}

open_firewall_client() {
  [[ "$OPEN_FIREWALL" == "1" ]] || return 0
  if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    info "Ensuring firewalld allows Input Leap port $PORT"
    # Outbound is usually allowed; open inbound too in case roles flip.
    if firewall-cmd --permanent --add-port="${PORT}/tcp" >/dev/null 2>&1; then
      firewall-cmd --reload >/dev/null 2>&1 || true
      ok "firewalld: ${PORT}/tcp permanent"
    else
      warn "firewalld change failed (may need: sudo firewall-cmd --permanent --add-port=${PORT}/tcp && sudo firewall-cmd --reload)"
    fi
  else
    warn "firewalld not active; if connection still fails, allow TCP $PORT on both machines"
  fi
}

# --- main ---
ensure_pem
write_local_fingerprint
open_firewall_client

FP=""
if [[ -n "$SERVER_FINGERPRINT" ]]; then
  FP="$(normalize_fp "$SERVER_FINGERPRINT")"
  ok "Using SERVER_FINGERPRINT from environment"
elif FP="$(fetch_server_fingerprint_via_ssh)"; then
  ok "Got fingerprint over SSH"
elif [[ -n "$SERVER_IP" ]] && FP="$(fetch_server_fingerprint_via_openssl "$SERVER_IP")"; then
  ok "Got fingerprint over TLS from $SERVER_IP"
else
  cat <<EOF

Could not obtain the server fingerprint automatically.

Do this on the WORKING server, then re-run:

  # Linux server:
  cat ~/.local/share/input-leap/SSL/Fingerprints/Local.txt

  # Or copy the SSL Fingerprint shown in the Input Leap GUI.

Then on this laptop:
  export SERVER_IP=<server-ip>
  export SERVER_FINGERPRINT='v2:sha256:..paste..'
  $0

EOF
  if [[ -z "$SERVER_IP" && -z "$SERVER_HOST" ]]; then
    die "Set SERVER_IP and/or SERVER_HOST (or SERVER_FINGERPRINT) and re-run"
  fi
  die "server fingerprint unavailable (is Input Leap server running with SSL?)"
fi

trust_server_fingerprint "$FP"

if [[ -n "$SERVER_IP" ]]; then
  info "Connectivity check"
  if test_tcp "$SERVER_IP"; then
    echo | timeout 8 openssl s_client -connect "${SERVER_IP}:${PORT}" 2>/dev/null \
      | head -n 15 | sed 's/^/    /' || warn "openssl s_client did not complete (still may work in GUI)"
  fi
fi

cat <<EOF

=== Secure-socket fix applied ===

Client local fingerprint (for server TrustedClients.txt if required):
$(sed 's/^/  /' "$LOCAL_FP")

Next in Input Leap GUI on this laptop:
  1. Client mode
  2. Server: ${SERVER_IP:-<your-server-ip>}
  3. Enable SSL: ON (match the server)
  4. Screen name must exist in the server layout
  5. Start — accept any fingerprint prompt

If it still fails with secure socket:
  - On the server, confirm SSL is enabled and the server is started
  - Confirm versions are close (both Input Leap 3.x ideally)
  - If server requires client certs, run ./03-trust-this-client-on-server.sh there
  - Re-run ./01-diagnose-client.sh and compare fingerprints

EOF
