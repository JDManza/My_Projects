#!/bin/bash

# Dirs
SOURCE_DIR=""
DEST_DIR=""

# Create source and destination directories if they don't exist already
mdkir -p "$DEST_DIR"
mkdir -p "$SOURCE_DIR"

# Find and extract matching tar files
for archive in "$SOURCE_DIR"/rhel8_*.tar; do
    # Check if any files match
    [ -e "$archive" ] || {
        echo "[INFO] No matching tar files found in $SOURCE_DIR"
        exit 0
    }

    echo "[INFO] Extracting $archive to $DEST_DIR..."

    case "$archive" in 
        *.tar.gz|*.tgz)  tar -xzvf "$archive" -C "$DEST_DIR" ;;
        *.tar.bz2)       tar -xjvf "$archive" -C "$DEST_DIR" ;;
        *.tar)           tar -xvf "$archive" -C "$DEST_DIR" ;;
        *                echo "[WARN] Skipping unsupported file: $archive" ;;
    esac
done

echo "[DONE] All matching tar files have been extracted."
