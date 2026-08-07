#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING_DIR="$ROOT_DIR/build/dmg"
DMG_PATH="$ROOT_DIR/build/NotchHub.dmg"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

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

if [[ "$SIGN_IDENTITY" != "-" ]]; then
    codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
fi

echo "Built $DMG_PATH"
