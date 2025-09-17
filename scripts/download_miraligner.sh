#!/usr/bin/env bash

set -euo pipefail

# Define destination directory and file
DEST_DIR="bin"
DEST_FILE="$DEST_DIR/miraligner.jar"
JAR_URL="https://github.com/lpantano/seqbuster/raw/miraligner/modules/miraligner/miraligner.jar"

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Download the JAR file
echo "Downloading miraligner.jar from GitHub..."
curl -L -o "$DEST_FILE" "$JAR_URL"

# Check if the file was downloaded successfully
if [[ -f "$DEST_FILE" ]]; then
    echo "miraligner.jar downloaded successfully to $DEST_FILE"
else
    echo "ERROR: Failed to download miraligner.jar"
    exit 1
fi
