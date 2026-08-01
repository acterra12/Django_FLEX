#!/usr/bin/env bash
# Optional: save Docker images/containers list from OLD laptop.
set -euo pipefail

OUT_DIR="${1:-./reports/docker-export-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not installed; nothing to export"
  exit 0
fi

echo "=== Docker export → $OUT_DIR ==="
docker ps -a > "$OUT_DIR/containers.txt" || true
docker images > "$OUT_DIR/images.txt" || true
docker volume ls > "$OUT_DIR/volumes.txt" || true
docker network ls > "$OUT_DIR/networks.txt" || true

read -r -p "Also docker save ALL images (can be huge)? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  mapfile -t IMAGES < <(docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>' || true)
  for img in "${IMAGES[@]}"; do
    safe="$(echo "$img" | tr '/:' '__')"
    echo "Saving $img..."
    docker save "$img" | gzip > "$OUT_DIR/$safe.tar.gz"
  done
fi

echo "Wrote $OUT_DIR"
