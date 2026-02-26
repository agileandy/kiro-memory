#!/bin/bash

# Simple hook to track prompt count
COUNT_FILE="./prompt-count.json"

# Initialize if doesn't exist
if [ ! -f "$COUNT_FILE" ]; then
    echo '{"count": 0, "last_updated": ""}' > "$COUNT_FILE"
fi

# Read current count
CURRENT=$(jq -r '.count' "$COUNT_FILE")

# Increment
NEW_COUNT=$((CURRENT + 1))

# Update file
jq --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
   ".count = $NEW_COUNT | .last_updated = \$timestamp" \
   "$COUNT_FILE" > "$COUNT_FILE.tmp" && mv "$COUNT_FILE.tmp" "$COUNT_FILE"

echo "✅ Prompt count: $NEW_COUNT"
