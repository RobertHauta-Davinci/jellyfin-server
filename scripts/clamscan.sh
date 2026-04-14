#!/bin/bash
# Scan media downloads for threats using ClamAV (runs on host)
# Manual: sudo /opt/jellyfin/scripts/clamscan.sh
# Cron:   0 */6 * * * /opt/jellyfin/scripts/clamscan.sh

SCAN_DIR="/mnt/media/downloads"
LOG_FILE="/var/log/clamav/media-scan.log"

mkdir -p "$(dirname "$LOG_FILE")"

echo "=== ClamAV scan started: $(date) ===" | tee -a "$LOG_FILE"

clamscan -r --infected --remove=no "$SCAN_DIR" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "=== Scan complete: No threats found ===" | tee -a "$LOG_FILE"
elif [ $EXIT_CODE -eq 1 ]; then
    echo "=== WARNING: Threats found! Review above and remove manually ===" | tee -a "$LOG_FILE"
else
    echo "=== Scan error (exit code $EXIT_CODE) ===" | tee -a "$LOG_FILE"
fi
