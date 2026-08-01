#!/usr/bin/env bash
# Explain / help fix Input Leap copy-paste (clipboard sharing) on Linux.
set -euo pipefail

info() { echo "==> $*"; }
ok() { echo "    OK: $*"; }
warn() { echo "    WARN: $*"; }
fix() { echo "    FIX: $*"; }

SESSION="${XDG_SESSION_TYPE:-unknown}"
DESKTOP="${XDG_CURRENT_DESKTOP:-unknown}"
DO_INSTALL="${DO_INSTALL:-0}"   # set DO_INSTALL=1 to attempt package install

echo "=== Input Leap clipboard check ==="
echo "Session: $SESSION"
echo "Desktop: $DESKTOP"
echo "Wayland display: ${WAYLAND_DISPLAY:-none}"
echo "X11 display:     ${DISPLAY:-none}"
echo

fedora_version() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${VERSION_ID:-unknown}"
  else
    echo "unknown"
  fi
}

has_gnome_xorg_session_file() {
  [[ -f /usr/share/xsessions/gnome-xorg.desktop ]] \
    || [[ -f /usr/share/xsessions/gnome.desktop ]] \
    || compgen -G '/usr/share/xsessions/*xorg*.desktop' >/dev/null 2>&1
}

list_login_sessions() {
  echo "-- Login sessions currently installed --"
  if [[ -d /usr/share/wayland-sessions ]]; then
    echo "  Wayland:"
    for f in /usr/share/wayland-sessions/*.desktop; do
      [[ -e "$f" ]] || continue
      name="$(grep -E '^Name=' "$f" | head -1 | cut -d= -f2-)"
      echo "    - ${name:-$(basename "$f")}"
    done
  fi
  if [[ -d /usr/share/xsessions ]]; then
    echo "  X11:"
    local any=0
    for f in /usr/share/xsessions/*.desktop; do
      [[ -e "$f" ]] || continue
      any=1
      name="$(grep -E '^Name=' "$f" | head -1 | cut -d= -f2-)"
      echo "    - ${name:-$(basename "$f")}"
    done
    [[ "$any" -eq 1 ]] || echo "    (none — this is why the gear menu only shows GNOME / GNOME Classic)"
  else
    echo "  X11: (no /usr/share/xsessions directory)"
  fi
  echo
}

list_login_sessions

FEDORA_VER="$(fedora_version)"
if [[ -f /etc/fedora-release ]]; then
  echo "Fedora version: $FEDORA_VER"
  echo
fi

if [[ "$SESSION" == "wayland" ]]; then
  warn "You are on Wayland."
  warn "Input Leap clipboard sharing is NOT supported on Wayland"
  warn "(upstream: input-leap#1698 / #1922)."
  warn "'GNOME' and 'GNOME Classic' are BOTH Wayland on modern Fedora."
  echo

  if has_gnome_xorg_session_file; then
    ok "An X11 session file is installed."
    fix "Log out. At the GDM password screen click the gear and choose 'GNOME on Xorg'."
    fix "Then: echo \$XDG_SESSION_TYPE   # must print x11"
  else
    info "No GNOME Xorg session is installed — that is why the gear only lists Wayland options."
    echo
    # Fedora 43+ removed official GNOME X11 packages.
    if [[ "$FEDORA_VER" =~ ^[0-9]+$ ]] && [[ "$FEDORA_VER" -ge 43 ]]; then
      warn "Fedora $FEDORA_VER removed official 'GNOME on Xorg' packages."
      echo
      fix "Option A — restore GNOME on Xorg via community COPR (Fedora 43/44):"
      cat <<'EOF'
        sudo dnf copr enable frantisekz/GNOME-X11 -y
        sudo dnf update -y
        sudo dnf install -y xorg-x11-xinit gnome-session-xsession gnome-classic-session-xsession
        # then log out → gear → "GNOME on Xorg"
EOF
      echo
      fix "Option B — use an X11 desktop that Fedora still ships, e.g.:"
      cat <<'EOF'
        sudo dnf install -y @mate-desktop-environment
        # or: sudo dnf install -y @cinnamon-desktop-environment
        # log out → gear → MATE / Cinnamon (X11) → restart Input Leap
EOF
      echo
      fix "Option C — stay on Wayland and accept no Input Leap clipboard (mouse/keyboard only)."
    else
      fix "Install the official Xorg session packages, then log out:"
      cat <<'EOF'
        sudo dnf install -y gnome-session-xsession gnome-classic-session-xsession
        # log out → gear → "GNOME on Xorg"
        echo $XDG_SESSION_TYPE   # should print: x11
EOF
      if [[ "$DO_INSTALL" == "1" ]]; then
        info "DO_INSTALL=1 set — attempting package install"
        DNF_BIN="$(command -v dnf5 || command -v dnf || true)"
        if [[ -z "$DNF_BIN" ]]; then
          warn "Neither dnf5 nor dnf found. Are you on the Fedora laptop host?"
          warn "Run: cat /etc/os-release; command -v dnf5 dnf"
        elif sudo "$DNF_BIN" install -y gnome-session-xsession gnome-classic-session-xsession; then
          ok "Packages installed. Log out and pick 'GNOME on Xorg'."
        else
          warn "install failed. If 'No match', your Fedora release no longer ships Xorg GNOME — use the COPR steps above."
        fi
      else
        echo
        fix "Re-run with DO_INSTALL=1 to have this script run the dnf install for you:"
        echo "        DO_INSTALL=1 ./04-fix-clipboard.sh"
      fi
    fi
  fi
elif [[ "$SESSION" == "x11" ]]; then
  ok "Session is X11 — Wayland is not the blocker."
  info "If copy-paste still fails, check:"
  echo "  1. Input Leap Preferences → clipboard sharing enabled on BOTH machines"
  echo "  2. Both sides actually connected"
  echo "  3. Similar Input Leap versions"
  echo "  4. Try copying a short plain-text string (large/image clipboards often fail)"
  echo "  5. Restart Input Leap on both machines"
else
  warn "Could not determine session type (got: $SESSION)."
  fix "Run: echo \$XDG_SESSION_TYPE"
fi

echo
echo "=== Done ==="
