#!/usr/bin/env bash
# Upload media files to Hetzner Storage Box via rsync over SSH.
#
# Usage: ./scripts/upload.sh <local_path> <remote_subpath>
#
# Examples:
#   ./scripts/upload.sh "./movies/Tears of Steel (2012)" movies
#   ./scripts/upload.sh ./tv/Breaking\ Bad tv
#
# Requires STORAGEBOX_USER and STORAGEBOX_HOST environment variables,
# or set them in your .env file.

set -euo pipefail

LOCAL_PATH="$1"
REMOTE_SUBPATH="${2:-movies}"

STORAGEBOX_USER="${STORAGEBOX_USER:?Set STORAGEBOX_USER in .env or environment}"
STORAGEBOX_HOST="${STORAGEBOX_HOST:-${STORAGEBOX_USER}.your-storagebox.de}"
STORAGEBOX_PORT="${STORAGEBOX_PORT:-23}"

if [ ! -e "$LOCAL_PATH" ]; then
    echo "Error: Path not found: $LOCAL_PATH"
    exit 1
fi

echo "Uploading to ${STORAGEBOX_USER}@${STORAGEBOX_HOST}:${REMOTE_SUBPATH}/ ..."

rsync -avz --progress \
    -e "ssh -p ${STORAGEBOX_PORT}" \
    "$LOCAL_PATH" \
    "${STORAGEBOX_USER}@${STORAGEBOX_HOST}:./${REMOTE_SUBPATH}/"

echo "Upload complete. Jellyfin will detect new files on next library scan."
echo "To trigger a scan now, go to Dashboard > Libraries > Scan All Libraries."
