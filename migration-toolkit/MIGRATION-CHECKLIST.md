# Migration checklist

## Old laptop

- [ ] Run `./01-inventory.sh` and keep the report
- [ ] Run `./00-export-desktop-snapshot.sh`
- [ ] Optional: `./04-export-docker.sh`
- [ ] Prep SSH (`./old-laptop-prep-ssh.sh`) **or** plug USB
- [ ] Do **not** factory-reset until new laptop verifies

## Transfer

- [ ] Real rsync completed (not dry-run)
- [ ] `du -sh ~/migration-incoming/home-mirror` shows expected size (~tens of GB)
- [ ] `./00-diagnose.sh` → `READY_TO_IMPORT`

## New laptop import

- [ ] `./03-import-home.sh ~/migration-incoming/home-mirror`
- [ ] `./05-verify-migration.sh` passes
- [ ] `ssh-add` works with migrated keys
- [ ] Spot-check `~/development`, Documents, browser if migrated
- [ ] `./06-new-pc-ai-setup.sh`
- [ ] Optional desktop/GNOME/memory scripts

## Adam's Aug 1 status (from session paste)

- [x] Toolkit present on new laptop (`~/Downloads/transfer`)
- [x] Staging dir exists (`~/migration-incoming/home-mirror`)
- [ ] Staging populated (currently **EMPTY** — blocked)
- [ ] Real network/USB pull
- [ ] Import into `$HOME`
- [ ] Verify + AI setup
