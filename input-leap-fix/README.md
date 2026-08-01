# Input Leap: fix "failed to connect to secure socket"

This toolkit is for the **new Fedora laptop** (`ascerra-dev`) acting as an Input Leap **client** against a **working server** on your LAN.

The error almost always means the SSL handshake failed: missing local cert, untrusted server fingerprint, or SSL enabled on only one side.

## Fast path (run on the new laptop)

```bash
cd ~/path/to/Django_FLEX/input-leap-fix   # or copy this folder onto the laptop
chmod +x *.sh

# 1) See what is broken locally
./01-diagnose-client.sh

# 2) Fix SSL + trust the working server
#    Prefer SSH if you can log into the server:
export SERVER_HOST=adam@192.168.1.42   # user@ip of the WORKING Input Leap server
export SERVER_IP=192.168.1.42          # IP/hostname Input Leap should connect to
./02-fix-secure-socket.sh

# If you cannot SSH, still run with SERVER_IP only — the script will
# pull the fingerprint over openssl when the server is listening on 24800.
```

Then in the Input Leap GUI on the laptop:

1. Mode: **Client**
2. Server IP: same as `SERVER_IP`
3. Screen name: exactly the name configured on the server layout
4. **Enable SSL** checked (same as the server)
5. Apply / Reload, then Start

If a fingerprint dialog appears, **Accept** it.

## What the fix does

| Step | Action |
|------|--------|
| Cert | Creates `Input Leap.pem` if missing |
| Local fingerprint | Writes `SSL/Fingerprints/Local.txt` |
| Trust | Copies server `Local.txt` into this client's `TrustedServers.txt` |
| Reachability | Tests TCP/TLS to `SERVER_IP:24800` |
| Firewall | Opens client outbound (and optional inbound) for `24800` via firewalld when present |

## On the working server (only if client cert checking is on)

If the server has **Require client certificate** enabled (or you run `input-leaps` from CLI without `--disable-client-cert-checking`), also run:

```bash
# on the WORKING server
./03-trust-this-client-on-server.sh
# paste the client's Local.txt fingerprint when prompted,
# or set CLIENT_FINGERPRINT='v2:sha256:...'
```

Most GUI server setups leave client-cert checking **off**, so step 2 alone is enough.

## Manual GUI fallback

1. On the **server**: note the SSL fingerprint shown in the GUI (or open `~/.local/share/input-leap/SSL/Fingerprints/Local.txt`).
2. On the **laptop**: stop Input Leap, then either Accept the fingerprint prompt or paste that line into:

   `~/.local/share/input-leap/SSL/Fingerprints/TrustedServers.txt`

   (also check `~/.local/share/InputLeap/...` if that path exists.)
3. Toggle **Enable SSL** off → Apply → on → Apply on both machines if the `.pem` was missing.
4. Confirm both machines use the same Input Leap major version when possible.

## Copy-paste not working

If mouse/keyboard cross the machines but **clipboard does not**, run:

```bash
./04-fix-clipboard.sh
```

On Fedora, **GNOME** and **GNOME Classic** are both Wayland. Input Leap cannot sync clipboards on Wayland ([upstream #1698](https://github.com/input-leap/input-leap/issues/1698)).

If the login gear has no **GNOME on Xorg**:

```bash
# Fedora 41/42 (official packages)
sudo dnf install -y gnome-session-xsession gnome-classic-session-xsession
# log out → gear → GNOME on Xorg → echo $XDG_SESSION_TYPE  # x11

# Fedora 43/44 (official Xorg GNOME removed — community COPR)
sudo dnf copr enable frantisekz/GNOME-X11 -y
sudo dnf update -y
sudo dnf install -y xorg-x11-xinit gnome-session-xsession gnome-classic-session-xsession
# log out → gear → GNOME on Xorg → echo $XDG_SESSION_TYPE  # x11
```

Or install an X11 desktop Fedora still ships (`@mate-desktop-environment` / `@cinnamon-desktop-environment`) and run Input Leap there.

Clipboard sharing must also be enabled in Input Leap preferences on **both** machines.

## Common gotchas after a laptop migration

- Fresh home → empty SSL dir → no trust → secure socket fails.
- Screen name changed (`ascerra-dev` vs old hostname) → server rejects after TLS succeeds; rename in the server layout.
- Server still has the old client name only — add/rename the screen on the server.
- Wayland: mouse/keyboard may work via portals, but **copy-paste will not** until you switch to X11.
