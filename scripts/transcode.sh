#!/usr/bin/env bash
# Pre-transcode media to H.264 MP4 for maximum client compatibility.
# Uses Intel QSV hardware acceleration when available.
#
# Usage: ./scripts/transcode.sh <input_file> [output_directory]
#
# Output format: H.264 video, AAC audio, MP4 container, 1080p max.
# This ensures direct play on virtually all Jellyfin clients.

set -euo pipefail

INPUT="$1"
OUTPUT_DIR="${2:-.}"

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

BASENAME="$(basename "${INPUT%.*}")"
OUTPUT="${OUTPUT_DIR}/${BASENAME}.mp4"

if [ -f "$OUTPUT" ]; then
    echo "Error: Output file already exists: $OUTPUT"
    exit 1
fi

# Check for Intel QSV support
if ffmpeg -hide_banner -hwaccels 2>/dev/null | grep -q qsv; then
    echo "Using Intel QSV hardware acceleration"
    ffmpeg -hwaccel qsv -i "$INPUT" \
        -c:v h264_qsv -preset medium -global_quality 22 \
        -vf "scale_qsv=-1:min(1080\,ih)" \
        -c:a aac -b:a 192k -ac 2 \
        -c:s mov_text \
        -movflags +faststart \
        "$OUTPUT"
else
    echo "QSV not available — using software encoding"
    ffmpeg -i "$INPUT" \
        -c:v libx264 -preset medium -crf 22 \
        -vf "scale=-2:min(1080\,ih)" \
        -c:a aac -b:a 192k -ac 2 \
        -c:s mov_text \
        -movflags +faststart \
        "$OUTPUT"
fi

echo "Transcoded: $OUTPUT"
