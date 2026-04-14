#!/bin/bash
# Scan media downloads for threats using ClamAV
# Run from the server: sudo docker exec clamav /scripts/clamscan.sh
# Or schedule via cron: 0 */6 * * * docker exec clamav /scripts/clamscan.sh

SCAN_DIR="/media/downloads"
LOG_FILE="/var/lib/clamav/scan.log"

echo "=== ClamAV scan started: $(date) ===" | tee -a "$LOG_FILE"

clamscan -r --infected --remove=no "$SCAN_DIR" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "=== Scan complete: No threats found ===" | tee -a "$LOG_FILE"
elif [ $EXIT_CODE -eq 1 ]; then
    echo "=== WARNING: Threats found! Check log above ===" | tee -a "$LOG_FILE"
else
    echo "=== Scan error (exit code $EXIT_CODE) ===" | tee -a "$LOG_FILE"
fi
