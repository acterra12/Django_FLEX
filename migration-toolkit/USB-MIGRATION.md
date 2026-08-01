# USB migration

Use when SSH/LAN is unavailable or unreliable.

1. Plug in a drive with **>80 GB free** (your scan was ~75 GB).
2. On **old**:

```bash
./02-export-usb.sh /run/media/$USER/USB_LABEL
```

3. On **new**:

```bash
./03-import-usb.sh /run/media/$USER/USB_LABEL
./00-diagnose.sh
./03-import-home.sh ~/migration-incoming/home-mirror
```

The USB export also copies this toolkit to `USB/transfer/` for convenience.
