# Laptop Migration Toolkit (Fedora → Fedora)

Move your old Linux laptop home (projects, dotfiles, desktop, AI/memory stack) onto a new machine with rsync, verification, and optional post-import setup.

If you are stuck with an empty `~/migration-incoming/home-mirror` after a dry-run, start here:

→ **[YOU-ARE-HERE.md](./YOU-ARE-HERE.md)**

## Quick map

| Phase | Where | Script |
|-------|--------|--------|
| Inventory old machine | Old | `01-inventory.sh` |
| Prep SSH on old | Old | `old-laptop-prep-ssh.sh` |
| Pull over LAN | New | `new-laptop-pull-all.sh` |
| Export to USB | Old | `02-export-usb.sh` |
| Import from mirror/USB | New | `03-import-home.sh` / `03-import-usb.sh` |
| Verify | New | `05-verify-migration.sh` |
| AI / Cursor / tools | New | `06-new-pc-ai-setup.sh` |
| Memory stack | New | `07-setup-memory-stack.sh` |
| Desktop / GNOME | New | `08-restore-desktop.sh`, `restore-gnome-extensions.sh` |

## Safety rules

1. **Dry-run ≠ done.** A listing with `(DRY RUN)` and ~0 disk growth means nothing copied.
2. **Import refuses empty mirrors** (`03-import-home.sh` aborts unless you pass `--force-empty`).
3. Keep the old laptop until `05-verify-migration.sh` and spot checks pass.
4. Secrets (SSH keys, browser profiles, password stores) need a conscious include — review `rsync-excludes.txt`.

## Network flow (default)

```bash
# OLD
./01-inventory.sh
./old-laptop-prep-ssh.sh

# NEW
export OLD_HOST=you@old-laptop-ip
./new-laptop-pull-all.sh          # writes ~/migration-incoming/home-mirror
./00-diagnose.sh                  # must say READY_TO_IMPORT
./03-import-home.sh ~/migration-incoming/home-mirror
./05-verify-migration.sh
./06-new-pc-ai-setup.sh
```

## USB flow

See [USB-MIGRATION.md](./USB-MIGRATION.md). Network notes: [NETWORK-MIGRATION.md](./NETWORK-MIGRATION.md). Full checklist: [MIGRATION-CHECKLIST.md](./MIGRATION-CHECKLIST.md).
