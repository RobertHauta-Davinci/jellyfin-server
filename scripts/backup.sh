#!/usr/bin/env bash
# Backup Jellyfin config from the cloud server to your local machine.
# Run this locally to pull a backup, or on the server to backup to the media volume.
#
# Usage:
#   Local:  ./scripts/backup.sh pull           # Download config from server
#   Server: ./scripts/backup.sh local          # Backup config to /mnt/media/backups
#
# Cron example (daily at 3 AM, run on the server):
#   0 3 * * * /opt/jellyfin/scripts/backup.sh local >> /var/log/jellyfin-backup.log 2>&1

set -euo pipefail

MODE="${1:-local}"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"

if [ "$MODE" = "pull" ]; then
    # Pull backup from server to local machine
    SERVER_IP="${SERVER_IP:?Set SERVER_IP in .env or environment}"
    SERVER_USER="${SERVER_USER:-jellyfin}"
    LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR:-./backups}"

    mkdir -p "$LOCAL_BACKUP_DIR"

    echo "[${TIMESTAMP}] Pulling Jellyfin config backup from ${SERVER_IP}..."

    rsync -az --progress \
        -e "ssh" \
        --exclude="cache/" \
        --exclude="transcodes/" \
        --exclude="log/" \
        "${SERVER_USER}@${SERVER_IP}:/opt/jellyfin/config/" \
        "${LOCAL_BACKUP_DIR}/config-${TIMESTAMP}/"

    echo "[${TIMESTAMP}] Backup saved to: ${LOCAL_BACKUP_DIR}/config-${TIMESTAMP}/"

elif [ "$MODE" = "local" ]; then
    # On-server backup to the media block volume
    CONFIG_DIR="${CONFIG_DIR:-/opt/jellyfin/config}"
    BACKUP_DIR="/mnt/media/backups/jellyfin-config"

    mkdir -p "$BACKUP_DIR"

    echo "[${TIMESTAMP}] Backing up Jellyfin config..."

    rsync -az --delete \
        --exclude="cache/" \
        --exclude="transcodes/" \
        --exclude="log/" \
        "${CONFIG_DIR}/" \
        "${BACKUP_DIR}/"

    echo "[${TIMESTAMP}] Backup complete: ${BACKUP_DIR}/"
else
    echo "Usage: $0 [pull|local]"
    exit 1
fi
