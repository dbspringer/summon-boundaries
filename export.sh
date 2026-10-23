#!/bin/bash

# Export Summon Boundaries as a distributable zip file, for a manual upload while the
# release workflow has no CurseForge or Wago keys.
# Usage: ./export.sh <version> [destination]
# Example: ./export.sh 1 ~/Desktop

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_NAME="SummonBoundaries"
TOC="$SCRIPT_DIR/$ADDON_NAME.toc"

# Releases are plain numbers that go up by one each time (1, 2, 3).
VERSION="$1"
if ! [[ "$VERSION" =~ ^[1-9][0-9]*$ ]]; then
    echo "Usage: ./export.sh <version> [destination]"
    echo "Error: the version must be a whole number, like 1"
    exit 1
fi

# Get destination from argument or use current directory
DEST="${2:-.}"
DEST="$(cd "$DEST" 2>/dev/null && pwd)" || { echo "Error: Invalid destination '$2'"; exit 1; }

ZIP_NAME="$ADDON_NAME.$VERSION.zip"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/$ADDON_NAME"

# The packager fills the version token from the tag. Do the same here.
sed "s/@project-version@/$VERSION/" "$TOC" > "$TEMP_DIR/$ADDON_NAME/$ADDON_NAME.toc"
cp "$SCRIPT_DIR/LICENSE" "$TEMP_DIR/$ADDON_NAME/"

# Ship exactly the files the TOC loads, so a new file can't be left out.
grep -v -E '^(#|[[:space:]]*$)' "$TOC" | tr -d '\r' | tr '\\' '/' | while read -r FILE; do
    if [ ! -f "$SCRIPT_DIR/$FILE" ]; then
        echo "Error: the TOC lists '$FILE', which does not exist"
        exit 1
    fi
    mkdir -p "$TEMP_DIR/$ADDON_NAME/$(dirname "$FILE")"
    cp "$SCRIPT_DIR/$FILE" "$TEMP_DIR/$ADDON_NAME/$FILE"
done

# Create zip file
rm -f "$DEST/$ZIP_NAME"
cd "$TEMP_DIR"
zip -r -q "$DEST/$ZIP_NAME" "$ADDON_NAME"

echo "Created: $DEST/$ZIP_NAME"
