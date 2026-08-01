# Fedora 44 recovery: black screen with `_` after GNOME-X11 COPR

The `frantisekz/GNOME-X11` COPR replaces core GNOME/GDM packages (epoch bump). On Fedora 44 that can leave you on a black screen with a lone `_` and no typing.

## Goal

Get a text login, undo the COPR, put Fedora’s GNOME packages back, reboot to a normal Wayland GNOME login.

Clipboard via Input Leap can wait — restore the desktop first.

---

## Step 1 — get a text console

Try these **in order**:

### A. Switch TTY (easiest)

On the black screen press:

- `Ctrl + Alt + F3` (try `F2` … `F6` if needed)

You want a `login:` prompt. Sign in as your user (`ascerra-dev`) and password.

If the keyboard seems dead: try another USB port / a wired keyboard. Some laptops need `Fn + Ctrl + Alt + F3`.

### B. GRUB rescue / multi-user

1. Reboot (`Ctrl + Alt + Del` often still works on the `_` screen).
2. At the GRUB menu (hold **Esc** or **Left Shift** while booting if it flashes past).
3. Highlight the normal Fedora kernel → press **e** to edit.
4. Find the line starting with `linux` / `linuxefi`.
5. At the **end** of that line add a space and:

   ```text
   systemd.unit=multi-user.target
   ```

6. Press **Ctrl + X** or **F10** to boot.

You should land on a text login (no GUI). Sign in.

### C. Live USB rescue (if A/B fail)

Boot a Fedora Workstation live USB → “Troubleshoot” / chroot into the installed system, or mount the root filesystem and use `chroot`. Then run the same undo commands below inside the installed root.

---

## Step 2 — undo the COPR and restore Fedora GNOME

Once you have a shell:

```bash
# Who/where
whoami
cat /etc/fedora-release
echo $XDG_SESSION_TYPE

# See display-manager failures
sudo systemctl --failed --no-pager
sudo journalctl -b -u gdm --no-pager | tail -n 80

# Remove X11 session packages (ignore errors if not installed)
sudo dnf5 remove -y gnome-session-xsession gnome-classic-session-xsession xorg-x11-xinit || true

# Disable the COPR so it stops overriding Fedora packages
sudo dnf5 copr remove frantisekz/GNOME-X11 || sudo dnf5 copr disable frantisekz/GNOME-X11 || true

# Put GNOME/GDM back on official Fedora 44 packages
sudo dnf5 distro-sync -y --refresh --allowerasing \
  gdm mutter gnome-shell gnome-session gnome-settings-daemon \
  gnome-shell-extensions mesa-dri-drivers

# Known F44 "_" screen fix when auth stacks break after upgrades
sudo authselect select local with-silent-lastlog with-mdns4 --force

# Prefer graphical boot again
sudo systemctl set-default graphical.target
sudo systemctl enable gdm.service

sudo reboot
```

After reboot you should get the normal **GNOME** (Wayland) login again.

---

## Step 3 — if it still shows `_`

From a TTY again:

```bash
sudo dnf5 distro-sync -y --refresh --allowerasing --setopt=protected_packages=
sudo authselect select local with-silent-lastlog with-mdns4 --force
sudo systemctl restart gdm
# or
sudo reboot
```

Nuclear-but-usually-safe graphics reset:

```bash
sudo dnf5 reinstall -y gdm mutter gnome-shell mesa-dri-drivers
sudo rpm --restore gdm mutter gnome-shell 2>/dev/null || true
sudo reboot
```

---

## After you’re back on the desktop

Do **not** re-enable `frantisekz/GNOME-X11` on this machine until you’re ready to risk another outage.

Safer options for Input Leap clipboard on Fedora 44:

1. Accept Wayland: mouse/keyboard via Input Leap, clipboard separate (e.g. pastebin / KDE Connect / shared notes).
2. Install a **separate X11 desktop** that Fedora still ships, and only use it when you need clipboard:

   ```bash
   sudo dnf5 install -y @mate-desktop-environment
   ```

   Log out → gear → **MATE** → use Input Leap there. Daily driver can stay GNOME Wayland.

---

## Commands to paste back here

If recovery fails, from the TTY run and paste:

```bash
cat /etc/fedora-release
rpm -q gdm mutter gnome-shell gnome-session
dnf5 copr list 2>/dev/null || true
systemctl --failed --no-pager
journalctl -b -u gdm --no-pager | tail -n 100
```
