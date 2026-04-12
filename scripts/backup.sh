#!/usr/bin/env bash
# Backup Jellyfin config to Hetzner Storage Box.
# Run this on the server (manually or via cron).
#
# Backs up the config directory (database, metadata, settings).
# Media files are already on the Storage Box — no need to back those up.
#
# Cron example (daily at 3 AM):
#   0 3 * * * /opt/jellyfin/scripts/backup.sh >> /var/log/jellyfin-backup.log 2>&1

set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-/opt/jellyfin/config}"
BACKUP_USER="${STORAGEBOX_USER:?Set STORAGEBOX_USER}"
BACKUP_HOST="${STORAGEBOX_HOST:-${BACKUP_USER}.your-storagebox.de}"
BACKUP_PORT="${STORAGEBOX_PORT:-23}"
BACKUP_PATH="./backups/jellyfin-config"

TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"

echo "[${TIMESTAMP}] Starting Jellyfin config backup..."

rsync -az --delete \
    -e "ssh -p ${BACKUP_PORT}" \
    --exclude="cache/" \
    --exclude="transcodes/" \
    --exclude="log/" \
    "${CONFIG_DIR}/" \
    "${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_PATH}/"

echo "[${TIMESTAMP}] Backup complete: ${BACKUP_PATH}/"
