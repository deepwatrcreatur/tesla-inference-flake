#!/usr/bin/env bash

# Tesla Inference Flake - Ollama Binary Update Automation (Enhanced)
# This script finds the latest stable Ollama release, dynamically discovers
# the correct Linux asset (handling naming changes), and updates the overlay.

set -euo pipefail

OVERLAY_FILE="overlays/ollama-official-binaries.nix"
REPO="ollama/ollama"

echo "Checking for latest Ollama release..."
# Get release info in one call
RELEASE_JSON=$(gh release view -R "$REPO" --json tagName,assets)
LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tagName')
VERSION="${LATEST_TAG#v}"
CURRENT_VERSION=$(grep 'version =' "$OVERLAY_FILE" | head -n1 | cut -d'"' -f2)

if [ "$VERSION" == "$CURRENT_VERSION" ]; then
    echo "Already at the latest version ($VERSION). No update needed."
    exit 0
fi

echo "New version found: $VERSION (current: $CURRENT_VERSION)"

# Dynamically discover the asset. Prefer .tar.zst, fallback to .tgz
# Excludes specialized variants like -rocm or -jetpack
echo "Discovering correct Linux asset..."
ASSET_INFO=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name == "ollama-linux-amd64.tar.zst" or .name == "ollama-linux-amd64.tgz") | "\(.name) \(.url)"' | head -n 1)

if [ -z "$ASSET_INFO" ]; then
    echo "Error: Could not find a compatible linux-amd64 asset for v$VERSION."
    echo "This might indicate a major change in Ollama's release structure."
    exit 1
fi

ASSET_NAME=$(echo "$ASSET_INFO" | cut -d' ' -f1)
URL=$(echo "$ASSET_INFO" | cut -d' ' -f2)

echo "Found asset: $ASSET_NAME"
echo "URL: $URL"

# Get current state from overlay for replacement anchor
CURRENT_URL=$(grep 'url =' "$OVERLAY_FILE" | head -n1 | cut -d'"' -f2)
CURRENT_HASH_LINE=$(grep 'hash =' "$OVERLAY_FILE" || grep 'sha256 =' "$OVERLAY_FILE" | head -n1)
OLD_HASH=$(echo "$CURRENT_HASH_LINE" | cut -d'"' -f2)
ATTR_NAME=$(echo "$CURRENT_HASH_LINE" | cut -d' ' -f1 | xargs)

echo "Prefetching new hash..."
PREFETCHED_HASH=$(nix-prefetch-url "$URL")

if [ -z "$PREFETCHED_HASH" ]; then
    echo "Error: Failed to prefetch hash for $URL"
    exit 1
fi

NEW_HASH=$(nix-hash --to-sri --type sha256 "$PREFETCHED_HASH")

echo "Updating $OVERLAY_FILE..."
# Atomic update of version, URL, and hash
TEMP_FILE=$(mktemp)
sed -e "s/version = \"$CURRENT_VERSION\";/version = \"$VERSION\";/" \
    -e "s|url = \"$CURRENT_URL\";|url = \"$URL\";|" \
    -e "s/$ATTR_NAME = \"$OLD_HASH\";/hash = \"$NEW_HASH\";/" \
    "$OVERLAY_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$OVERLAY_FILE"

echo "Successfully updated Ollama to v$VERSION"
echo "Asset: $ASSET_NAME"
echo "Hash: $NEW_HASH"
