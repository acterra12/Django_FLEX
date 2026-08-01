# GNOME extensions

Extensions usually live in:

```text
~/.local/share/gnome-shell/extensions
```

If that directory was included in the rsync, enable them after import:

```bash
./restore-gnome-extensions.sh
```

On Wayland you must log out/in; on Xorg, Alt+F2 → `r` may reload the shell.

If an extension fails to enable, install the matching package or from [extensions.gnome.org](https://extensions.gnome.org/) for your GNOME version.
