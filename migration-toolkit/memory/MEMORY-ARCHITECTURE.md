# Memory architecture (optional)

Lightweight local memory for AI tooling:

1. **recalld** — local daemon storing short memories (`~/.local/share/recalld`)
2. **Obsidian sync** — timer dumps memories into a vault note
3. **Cursor hook** — shell helper to inject recent memories into agent context

Install order on the new machine:

```bash
./07-setup-memory-stack.sh
# install recalld binary separately if you use it
systemctl --user enable --now recalld.service
systemctl --user enable --now memory-obsidian-sync.timer
```

Templates and units live next to this file.
