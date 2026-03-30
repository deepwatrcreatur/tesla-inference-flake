#!/usr/bin/env bash

# Tesla Inference Flake - Ollama Binary Update Automation
# This script finds the latest stable Ollama release, verifies the asset exists,
# and updates overlays/ollama-official-binaries.nix with the new version and hash.

set -euo pipefail

OVERLAY_FILE="overlays/ollama-official-binaries.nix"
REPO="ollama/ollama"

echo "Checking for latest Ollama release..."
LATEST_TAG=$(gh release view -R "$REPO" --json tagName --template '{{.tagName}}')
VERSION="${LATEST_TAG#v}"
CURRENT_VERSION=$(grep 'version =' "$OVERLAY_FILE" | head -n1 | cut -d'"' -f2)

if [ "$VERSION" == "$CURRENT_VERSION" ]; then
    echo "Already at the latest version ($VERSION). No update needed."
    exit 0
fi

echo "New version found: $VERSION (current: $CURRENT_VERSION)"

# Construct the asset URL using the new .tar.zst convention
ASSET_NAME="ollama-linux-amd64.tar.zst"
URL="https://github.com/$REPO/releases/download/v$VERSION/$ASSET_NAME"

echo "Verifying asset availability at $URL..."
if ! curl --output /dev/null --silent --head --fail "$URL"; then
    echo "Error: Asset $ASSET_NAME not found for release v$VERSION."
    echo "The naming convention might have changed. Manual intervention required."
    exit 1
fi

echo "Asset verified. Prefetching new hash..."
NEW_HASH=$(nix-prefetch-url "$URL")

if [ -z "$NEW_HASH" ]; then
    echo "Error: Failed to prefetch hash for $URL"
    exit 1
fi

echo "Updating $OVERLAY_FILE..."
OLD_HASH=$(grep 'sha256 =' "$OVERLAY_FILE" | head -n1 | cut -d'"' -f2)

# Atomic update using a temporary file and single sed command
TEMP_FILE=$(mktemp)
sed -e "s/version = \"$CURRENT_VERSION\";/version = \"$VERSION\";/" \
    -e "s/sha256 = \"$OLD_HASH\";/sha256 = \"$NEW_HASH\";/" \
    "$OVERLAY_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$OVERLAY_FILE"

echo "Successfully updated Ollama to v$VERSION"
echo "Hash: $NEW_HASH"
