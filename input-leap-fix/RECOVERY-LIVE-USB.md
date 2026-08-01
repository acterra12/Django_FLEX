# Next step: Fedora live USB rescue (when TTY/GRUB undo failed)

Use this if the laptop stays on a black screen with `_` and you cannot get a working text login.

You need another working computer + a USB stick (≥ 4 GB).

---

## 0. One more GRUB try (2 minutes, before making USB)

1. Power off hard (hold power 10s) → power on.
2. Mash **Esc** (UEFI) or **Left Shift** to get the **GRUB** menu.
3. If you see an **older kernel** under Advanced options — try that first.
4. Or highlight the current kernel → **e** → on the `linux`/`linuxefi` line:
   - delete `quiet` and `rhgb`
   - add at the end:

     ```text
     nomodeset systemd.unit=multi-user.target
     ```

5. **Ctrl+X** to boot.

If you get a text `login:`, sign in and jump to **“Fix commands”** below (same as chroot section).  
If still black/`_`, continue with the live USB.

---

## 1. Make a Fedora live USB (on any working PC)

1. Download **Fedora Workstation** ISO (44 if possible): https://fedoraproject.org/workstation/download/
2. Write it with [Fedora Media Writer](https://github.com/FedoraQt/MediaWriter/releases) or `dd`/`balenaEtcher`.
3. Plug USB into the broken laptop.
4. Power on → enter BIOS/boot menu (**F12** / **F10** / **Esc** — laptop dependent).
5. Boot the USB → **Try Fedora** / live session (do **not** reinstall yet).

---

## 2. Unlock disk + chroot (live session terminal)

Your install looked LUKS-encrypted earlier. In the live desktop open **Terminal**:

```bash
# See disks
lsblk -f

# Find the big LUKS partition (often nvme0n1p3) and the small boot/efi ones
# Example names — replace with YOURS from lsblk:
#   EFI:  nvme0n1p1  (vfat)
#   boot: nvme0n1p2  (ext4/xfs)
#   LUKS: nvme0n1p3  (crypto_LUKS)
```

Unlock and mount (edit device names to match `lsblk`):

```bash
sudo cryptsetup open /dev/nvme0n1p3 fedora_crypt   # type your disk passphrase
lsblk   # note the unlocked mapper + any fedora/root LVM or btrfs

sudo mkdir -p /mnt/sysroot

# --- If you see LVM (fedora/root) ---
sudo lvscan
sudo mount /dev/mapper/fedora-root /mnt/sysroot 2>/dev/null \
  || sudo mount /dev/mapper/fedora_crypt /mnt/sysroot

# --- If root is btrfs on the unlocked device ---
# sudo mount -o subvol=root /dev/mapper/fedora_crypt /mnt/sysroot

sudo mount /dev/nvme0n1p2 /mnt/sysroot/boot
sudo mount /dev/nvme0n1p1 /mnt/sysroot/boot/efi

sudo mount --bind /dev  /mnt/sysroot/dev
sudo mount --bind /proc /mnt/sysroot/proc
sudo mount --bind /sys  /mnt/sysroot/sys
sudo mount --bind /run  /mnt/sysroot/run
sudo mount -t tmpfs tmpfs /mnt/sysroot/tmp

sudo chroot /mnt/sysroot /bin/bash
```

Inside chroot you are “on” the installed system.

---

## 3. Fix commands (inside chroot)

```bash
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

cat /etc/fedora-release
rpm -q gdm mutter gnome-shell

# Kill the COPR override
dnf5 copr remove frantisekz/GNOME-X11 || dnf5 copr disable frantisekz/GNOME-X11 || true
rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:frantisekz:GNOME-X11.repo \
      /etc/yum.repos.d/*GNOME-X11* 2>/dev/null || true

dnf5 remove -y gnome-session-xsession gnome-classic-session-xsession || true

# Force Fedora packages back (this is the important one)
dnf5 distro-sync -y --refresh --allowerasing --setopt=protected_packages= \
  gdm mutter gnome-shell gnome-session gnome-settings-daemon \
  gnome-shell-extensions mesa-dri-drivers || \
dnf5 reinstall -y gdm mutter gnome-shell gnome-session

# F44 "_" screen auth fix
authselect select local with-silent-lastlog with-mdns4 --force

# Make sure we boot to multi-user first (safer), not broken GDM
systemctl set-default multi-user.target
systemctl disable gdm.service || true
systemctl enable getty@tty1.service || true

# SELinux relabel on next boot (important after chroot package changes)
touch /.autorelabel

exit   # leave chroot
sudo reboot
```

Remove the USB when rebooting.

---

## 4. After reboot (text mode on purpose)

You should get a text login (because default is `multi-user.target`).

```bash
# confirm packages look like Fedora, not COPR epoch weirdness
rpm -qi gdm | head
dnf5 copr list

# bring graphics back
sudo systemctl enable gdm.service
sudo systemctl set-default graphical.target
sudo systemctl start gdm
# if that fails:
sudo reboot
```

If GDM still dies with `_`:

```bash
sudo systemctl set-default multi-user.target
sudo dnf5 install -y @mate-desktop-environment lightdm
sudo systemctl disable gdm
sudo systemctl enable lightdm
sudo systemctl set-default graphical.target
sudo reboot
```

Then log into **MATE** — that gets a usable desktop without broken GDM.

---

## 5. Last resort: reinstall keeping /home

Only if package repair fails. From the live USB installer:

- Reinstall Fedora 44 Workstation
- Choose the existing disk carefully
- If the installer offers **custom** partitioning, keep the existing `/home` subvolume/partition and only replace root
- Or after a clean install, restore home from your old laptop / backup

Your files under `/home/ascerra-dev` are usually still on disk even when the GUI is broken — prefer chroot repair before reinstall.

---

## Paste back here if stuck mid-rescue

From the **live USB** (before or inside chroot):

```bash
lsblk -f
cat /mnt/sysroot/etc/fedora-release 2>/dev/null || cat /etc/fedora-release
chroot /mnt/sysroot rpm -q gdm mutter gnome-shell 2>/dev/null
ls /mnt/sysroot/etc/yum.repos.d | grep -i copr
```
