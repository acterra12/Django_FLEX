# Network migration

## Requirements

- Both laptops on the same LAN (or VPN with SSH)
- `openssh-server` running on the **old** laptop
- Enough free disk on the **new** laptop (your dry-run listed ~75 GB)

## Steps

### Old laptop

```bash
cd /path/to/migration-toolkit
./01-inventory.sh
./old-laptop-prep-ssh.sh
# note the IP printed / from `hostname -I`
```

### New laptop

```bash
cd ~/Downloads/transfer   # or clone/copy this toolkit
export OLD_HOST=ascerra@192.168.x.y   # OLD username@IP

# Optional plan
DRY_RUN=1 ./new-laptop-pull-all.sh

# Real copy into staging
./new-laptop-pull-all.sh

./00-diagnose.sh
# expect STATUS: READY_TO_IMPORT

./03-import-home.sh ~/migration-incoming/home-mirror
./05-verify-migration.sh
```

## If rsync exits 23

Code 23 means some files were skipped (permissions, vanished files, unsupported xattrs). Common on home dirs. Re-run the same pull command — rsync resumes. Inspect stderr for paths you care about (e.g. `.ssh`).

## If the link is flaky

Pull large trees in chunks:

```bash
export OLD_HOST=user@old
./transfer-chunk.sh development
./transfer-chunk.sh Documents
./transfer-chunk.sh .config
./transfer-chunk.sh .ssh
```

## Your current stuck state

You already have an empty `~/migration-incoming/home-mirror` and a toolkit copy under `~/Downloads/transfer`. You have **not** finished the real pull. Start at `./new-laptop-pull-all.sh` (without dry-run) after setting `OLD_HOST`.
