#!/usr/bin/env bash
# Upload media files to the cloud server via rsync over SSH.
#
# Usage: ./scripts/upload.sh <local_path> <media_type>
#
# Examples:
#   ./scripts/upload.sh "./movies/Tears of Steel (2012)" movies
#   ./scripts/upload.sh ./tv/Breaking\ Bad tv
#
# Requires SERVER_IP and SERVER_USER environment variables,
# or set them in your .env file.

set -euo pipefail

LOCAL_PATH="$1"
MEDIA_TYPE="${2:-movies}"

SERVER_IP="${SERVER_IP:?Set SERVER_IP in .env or environment}"
SERVER_USER="${SERVER_USER:-jellyfin}"

if [ ! -e "$LOCAL_PATH" ]; then
    echo "Error: Path not found: $LOCAL_PATH"
    exit 1
fi

echo "Uploading to ${SERVER_USER}@${SERVER_IP}:/mnt/media/${MEDIA_TYPE}/ ..."

rsync -avz --progress \
    -e "ssh" \
    "$LOCAL_PATH" \
    "${SERVER_USER}@${SERVER_IP}:/mnt/media/${MEDIA_TYPE}/"

echo "Upload complete. Jellyfin will detect new files on next library scan."
echo "To trigger a scan now, go to Dashboard > Libraries > Scan All Libraries."
