#!/usr/bin/env bash
# Explain / help fix Input Leap copy-paste (clipboard sharing) on Linux.
set -euo pipefail

info() { echo "==> $*"; }
ok() { echo "    OK: $*"; }
warn() { echo "    WARN: $*"; }
fix() { echo "    FIX: $*"; }

SESSION="${XDG_SESSION_TYPE:-unknown}"
DESKTOP="${XDG_CURRENT_DESKTOP:-unknown}"

echo "=== Input Leap clipboard check ==="
echo "Session: $SESSION"
echo "Desktop: $DESKTOP"
echo "Wayland display: ${WAYLAND_DISPLAY:-none}"
echo "X11 display:     ${DISPLAY:-none}"
echo

if [[ "$SESSION" == "wayland" ]]; then
  warn "You are on Wayland."
  warn "Input Leap clipboard sharing is NOT supported on Wayland"
  warn "(upstream: input-leap#1698 / #1922). Mouse/keyboard can work; copy-paste will not sync."
  echo
  info "Reliable fix: log into an X11 / Xorg session, then restart Input Leap."
  echo
  case "${DESKTOP,,}" in
    *gnome*|*ubuntu*)
      fix "At the GDM login screen: click your user → gear/cog → choose 'GNOME on Xorg' (or 'Ubuntu on Xorg'), then log in."
      ;;
    *kde*|*plasma*)
      fix "At the SDDM login screen: look for Session/Desktop and choose 'Plasma (X11)', then log in."
      ;;
    *)
      fix "At your display-manager login screen, pick the X11/Xorg session variant of your desktop, then log in."
      ;;
  esac
  echo
  fix "Confirm after login:  echo \$XDG_SESSION_TYPE   # should print: x11"
  echo
  if [[ -f /etc/gdm/custom.conf ]] || [[ -f /etc/gdm3/custom.conf ]]; then
    fix "Optional system-wide (GDM): set WaylandEnable=false under [daemon] in /etc/gdm/custom.conf, then reboot."
  fi
elif [[ "$SESSION" == "x11" ]]; then
  ok "Session is X11 — Wayland is not the blocker."
  info "If copy-paste still fails, check these next:"
  echo "  1. Input Leap Preferences → enable clipboard sharing / sync clipboard (both machines)."
  echo "  2. Both sides connected (not just SSL-ok in the UI)."
  echo "  3. Similar Input Leap versions on client and server."
  echo "  4. Huge clipboard contents can be dropped (size limit); try a short text string."
  echo "  5. Restart Input Leap on both machines after enabling clipboard."
else
  warn "Could not determine session type (got: $SESSION)."
  fix "Run: echo \$XDG_SESSION_TYPE"
fi

echo
echo "-- Quick local clipboard sanity (this machine only) --"
if command -v wl-paste >/dev/null 2>&1 && [[ "$SESSION" == "wayland" ]]; then
  echo "  wl-paste present (Wayland clipboard tools installed)"
elif command -v xclip >/dev/null 2>&1; then
  echo "  xclip present"
elif command -v xsel >/dev/null 2>&1; then
  echo "  xsel present"
else
  echo "  (no wl-paste/xclip/xsel found — not required for Input Leap, just for manual tests)"
fi

echo
echo "=== Done ==="
echo "Bottom line: on Fedora Wayland, Input Leap copy-paste between PCs will stay broken until you use X11 (or a different tool that supports Wayland clipboard)."
