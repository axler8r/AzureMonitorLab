#!/bin/bash
# Clean compiled Bicep artifacts (JSON files)
# Removes all generated ARM template JSON files while preserving bicepconfig.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_DIR="$(cd "$SCRIPT_DIR/../bicep" && pwd)"

echo "=== Cleaning Bicep Compiled Artifacts ==="
echo "Bicep directory: $BICEP_DIR"
echo ""

# Find and delete all .json files except bicepconfig.json
DELETED_COUNT=0

while IFS= read -r -d '' file; do
  if [[ "$(basename "$file")" != "bicepconfig.json" ]]; then
    echo "Deleting: ${file#$BICEP_DIR/}"
    rm -f "$file"
    ((DELETED_COUNT++))
  fi
done < <(find "$BICEP_DIR" -name "*.json" -type f -print0)

echo ""
if [ $DELETED_COUNT -eq 0 ]; then
  echo "No compiled artifacts found. Already clean!"
else
  echo "✓ Deleted $DELETED_COUNT compiled artifact(s)"
fi

echo ""
echo "=== Cleanup Complete ==="
