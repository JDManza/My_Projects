#!/usr/bin/env bash
#
# Usage:
#   ./save_docker_images.sh /path/to/backup [--export-containers]
#
# Example:
#   ./save_docker_images.sh /var/backups/docker --export-containers
#
# Run "# tar -tf /tmp/docker-backup-test/docker-images-*.tar | grep manifest.json" to validate

set -euo pipefail

BACKUP_DIR="${1:-/var/backups/docker}"
EXPORT_CONTAINERS=false
[[ "${2:-}" == "--export-containers" ]] && EXPORT_CONTAINERS=true

mkdir -p "$BACKUP_DIR"

# Timestamped archive name
TAR_BASENAME="docker-images-$(date +%Y%m%d-%H%M%S).tar"

echo "[*] Collecting Docker images and containers..."

# Get all image IDs (includes dangling)
mapfile -t IMAGE_IDS < <(docker images -a --quiet --no-trunc | sort -u)

# Get all container IDs
mapfile -t CONTAINER_IDS < <(docker ps -a --quiet --no-trunc | sort -u)

# Add images referenced by containers (some may not show up in `docker images`)
if [[ ${#CONTAINER_IDS[@]} -gt 0 ]]; then
    mapfile -t CONTAINER_IMAGE_IDS < <(
        docker inspect "${CONTAINER_IDS[@]}" --format '{{.Image}}' | sort -u
    )
else
    CONTAINER_IMAGE_IDS=()
fi

# Merge and dedupe all image IDs, make sure you don’t miss any images and don’t waste space saving duplicates.
ALL_IMAGE_IDS=($(printf "%s\n" "${IMAGE_IDS[@]}" "${CONTAINER_IMAGE_IDS[@]}" | sort -u))

if [[ ${#ALL_IMAGE_IDS[@]} -eq 0 ]]; then
    echo "[!] No Docker images found on this host."
    exit 1
fi

echo "[*] Saving ${#ALL_IMAGE_IDS[@]} images to $BACKUP_DIR/$TAR_BASENAME ..."
docker save -o "$BACKUP_DIR/$TAR_BASENAME" "${ALL_IMAGE_IDS[@]}"

echo "[+] Images saved: $BACKUP_DIR/$TAR_BASENAME"
ls -lh "$BACKUP_DIR/$TAR_BASENAME"
echo "[*] Done."

