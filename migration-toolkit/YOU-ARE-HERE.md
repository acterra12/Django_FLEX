# You Are Here — New Fedora Laptop Stuck Mid-Migration

## What happened

On the new laptop (`ascerra-dev@fedora`) you:

1. Ran an **rsync dry-run** that *listed* ~283k files / ~75 GB from the old machine.
2. Got `rsync error ... (code 23)` — partial / attr / permission issues during that scan.
3. Confirmed disk is basically empty: `/` is **5.5G used / 945G free**.
4. Found `~/migration-incoming/home-mirror` exists but is **empty**.
5. Ran `./03-import-home.sh ~/migration-incoming/home-mirror` — it correctly imported **0 bytes**.

**Nothing from the old laptop has been copied yet.** The toolkit scripts in `~/Downloads/transfer` are fine; the data pull never completed.

## Immediate goal

Get a real, non-dry-run copy of the old home into:

```text
~/migration-incoming/home-mirror/
```

Only after that directory is tens of GB (or matches your inventory) should you import into `~/`.

## Pick a path

### A) Network (preferred if both machines are on)

On **new** laptop:

```bash
cd ~/Downloads/transfer   # or wherever you keep this toolkit

# 1) Diagnose
./00-diagnose.sh

# 2) Prep old laptop SSH once (run ON OLD laptop, or from new if you can ssh in)
#    On OLD:
#      ./old-laptop-prep-ssh.sh

# 3) Real pull (NOT dry-run)
export OLD_HOST=USER@OLD_IP_OR_HOSTNAME   # e.g. adam@192.168.1.42
./new-laptop-pull-all.sh

# 4) Confirm size before import
du -sh ~/migration-incoming/home-mirror
./00-diagnose.sh

# 5) Import only if diagnose says READY
./03-import-home.sh ~/migration-incoming/home-mirror
```

### B) USB

On **old** laptop:

```bash
./02-export-usb.sh /run/media/$USER/YOUR_USB_LABEL
```

On **new** laptop:

```bash
./03-import-usb.sh /run/media/$USER/YOUR_USB_LABEL
# or, if USB already holds a home-mirror tree:
./03-import-home.sh /run/media/$USER/YOUR_USB_LABEL/home-mirror
```

## After a successful import

```bash
./05-verify-migration.sh
./06-new-pc-ai-setup.sh
./08-restore-desktop.sh          # if you exported a desktop snapshot
./07-setup-memory-stack.sh       # optional AI memory stack
./restore-gnome-extensions.sh    # optional
```

## Do not

- Do not treat a dry-run listing as a completed transfer.
- Do not run `03-import-home.sh` until `du -sh ~/migration-incoming/home-mirror` shows real data.
- Do not wipe the old laptop until `05-verify-migration.sh` passes and you have spot-checked projects/dotfiles.
