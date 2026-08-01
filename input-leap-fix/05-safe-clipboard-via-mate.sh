#!/usr/bin/env bash
# Safe Input Leap clipboard path on Fedora 44+: install MATE (X11) session.
# Do NOT use frantisekz/GNOME-X11 COPR — it can break GDM.
set -euo pipefail

info() { echo "==> $*"; }
ok() { echo "    OK: $*"; }
warn() { echo "    WARN: $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

DNF_BIN="$(command -v dnf5 || command -v dnf || true)"
[[ -n "$DNF_BIN" ]] || die "dnf5/dnf not found — run this on the Fedora laptop host"

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "OS: ${NAME:-?} ${VERSION_ID:-?}"
fi

echo "Session now: ${XDG_SESSION_TYPE:-unknown} / desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
echo

# Refuse if the dangerous COPR is enabled
if ls /etc/yum.repos.d/*GNOME-X11* >/dev/null 2>&1 || \
   "$DNF_BIN" copr list 2>/dev/null | grep -qi 'GNOME-X11'; then
  warn "GNOME-X11 COPR still present. Remove it before anything else:"
  echo "  sudo $DNF_BIN copr remove frantisekz/GNOME-X11"
  echo "  sudo $DNF_BIN distro-sync -y --refresh --allowerasing gdm mutter gnome-shell"
  exit 1
fi

info "Installing MATE desktop (X11 session) from official Fedora repos"
sudo "$DNF_BIN" install -y @mate-desktop-environment

ok "MATE installed"
cat <<'EOF'

=== Next steps ===

1. Log out of GNOME (do not reboot required).
2. At the GDM password screen, click the gear.
3. Choose **MATE**.
4. Log in, then confirm:
     echo $XDG_SESSION_TYPE    # must say: x11
5. Start Input Leap (client), connect to the server.
6. In Input Leap preferences on BOTH machines: enable clipboard sharing.
7. Test with a short plain-text copy/paste.

Daily driver tip:
  Use GNOME (Wayland) when you do not need clipboard sync.
  Switch to MATE only when you need Input Leap copy-paste.

If paste still fails after X11:
  - Confirm the other machine is not Wayland-only without clipboard support
  - Restart Input Leap on both sides
  - Check screen names match and the session is actually Connected

EOF
