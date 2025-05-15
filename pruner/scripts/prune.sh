#!/bin/bash
DATA_PATH="/home/hluser/hl/data"

# Default retention period (in days) if not specified in environment
PRUNE_RETAIN_DAYS=${PRUNE_RETAIN_DAYS:-7}

# Calculate retention hours
RETENTION_HOURS=$((PRUNE_RETAIN_DAYS * 24))

# Log startup for debugging
echo "$(date): Prune script started" >> /proc/1/fd/1

# Check if data directory exists
if [ ! -d "$DATA_PATH" ]; then
    echo "$(date): Error: Data directory $DATA_PATH does not exist." >> /proc/1/fd/1
    exit 1
fi

echo "$(date): Starting pruning process for files older than ${RETENTION_HOURS} hours (${PRUNE_RETAIN_DAYS} days)" >> /proc/1/fd/1

# Get directory size before pruning
size_before=$(du -sh "$DATA_PATH" | cut -f1)
files_before=$(find "$DATA_PATH" -type f | wc -l)
echo "$(date): Size before pruning: $size_before with $files_before files" >> /proc/1/fd/1

# Calculate minutes from hours for find command
MINUTES=$((RETENTION_HOURS * 60))
# Safer alternative using xargs:
find "$DATA_PATH" -mindepth 1 -depth -mmin +$MINUTES -type f -print0 | xargs -0 --no-run-if-empty rm -f

# Get directory size after pruning
size_after=$(du -sh "$DATA_PATH" | cut -f1)
files_after=$(find "$DATA_PATH" -type f | wc -l)
echo "$(date): Size after pruning: $size_after with $files_after files" >> /proc/1/fd/1
echo "$(date): Pruning completed. Reduced from $size_before to $size_after ($(($files_before - $files_after)) files removed)." >> /proc/1/fd/1