#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING_DIR="$ROOT_DIR/build/dmg"
DMG_PATH="$ROOT_DIR/build/NotchHub.dmg"

"$ROOT_DIR/scripts/build-app.sh" release

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$ROOT_DIR/build/NotchHub.app" "$STAGING_DIR/NotchHub.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "NotchHub" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Built $DMG_PATH"
