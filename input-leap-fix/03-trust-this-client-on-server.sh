#!/usr/bin/env bash
# Run on the WORKING Input Leap SERVER only when client-certificate
# checking is enabled and the client still fails after trusting the server.
set -euo pipefail

CLIENT_FINGERPRINT="${CLIENT_FINGERPRINT:-}"
PROFILE_DIR="${PROFILE_DIR:-}"

die() { echo "ERROR: $*" >&2; exit 1; }
ok() { echo "    OK: $*" >&2; }
info() { echo "==> $*" >&2; }

pick_profile_dir() {
  if [[ -n "$PROFILE_DIR" ]]; then
    printf '%s\n' "$PROFILE_DIR"
    return
  fi
  for d in \
    "${XDG_DATA_HOME:-$HOME/.local/share}/input-leap" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/InputLeap" \
    "$HOME/.local/share/input-leap" \
    "$HOME/.local/share/InputLeap" \
    "$HOME/Library/Application Support/input-leap"
  do
    [[ -d "$d/SSL" ]] && { printf '%s\n' "$d"; return; }
  done
  # Windows (Git Bash / WSL path to LocalAppData sometimes mounted)
  if [[ -n "${LOCALAPPDATA:-}" && -d "$LOCALAPPDATA/Input Leap/SSL" ]]; then
    printf '%s\n' "$LOCALAPPDATA/Input Leap"
    return
  fi
  printf '%s\n' "$HOME/.local/share/input-leap"
}

PROFILE_DIR="$(pick_profile_dir)"
FP_DIR="$PROFILE_DIR/SSL/Fingerprints"
TRUSTED_CLIENTS="$FP_DIR/TrustedClients.txt"
mkdir -p "$FP_DIR"

normalize_fp() {
  local raw="$1"
  raw="$(echo "$raw" | tr -d '\r' | head -n1 | xargs)"
  [[ -n "$raw" ]] || return 1
  if [[ "$raw" == v2:sha256:* ]]; then
    printf '%s\n' "$raw"
  elif [[ "$raw" == *:*:* ]]; then
    printf 'v2:sha256:%s\n' "$raw"
  else
    printf '%s\n' "$raw"
  fi
}

if [[ -z "$CLIENT_FINGERPRINT" ]]; then
  echo "Paste the CLIENT Local.txt fingerprint line, then press Enter:"
  echo "(from the laptop: cat ~/.local/share/input-leap/SSL/Fingerprints/Local.txt)"
  read -r CLIENT_FINGERPRINT
fi

FP="$(normalize_fp "$CLIENT_FINGERPRINT")" || die "empty fingerprint"
touch "$TRUSTED_CLIENTS"
if grep -Fxq "$FP" "$TRUSTED_CLIENTS"; then
  ok "Already in TrustedClients.txt: $FP"
else
  info "Adding client fingerprint"
  printf '%s\n' "$FP" >>"$TRUSTED_CLIENTS"
  ok "Wrote $TRUSTED_CLIENTS"
fi

echo
echo "TrustedClients.txt:"
sed 's/^/  /' "$TRUSTED_CLIENTS"
echo
echo "Reload/restart the Input Leap server, then reconnect the client."
echo "If you do not need client cert checking, disable it in the server GUI"
echo "or start input-leaps with --disable-client-cert-checking."
