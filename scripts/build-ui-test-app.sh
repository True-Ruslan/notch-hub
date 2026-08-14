#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMIT="${SOURCE_COMMIT:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
OUTPUT_DIR="$ROOT_DIR/build/ui-test"
APP="$OUTPUT_DIR/NotchHub.app"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
SOURCE_COMMIT="$SOURCE_COMMIT" NOTCHHUB_UI_TESTING=1 \
  bash "$ROOT_DIR/scripts/build-app.sh" debug
mv "$ROOT_DIR/build/NotchHub.app" "$APP"
test "$(plutil -extract NHSourceCommit raw "$APP/Contents/Info.plist")" = "$SOURCE_COMMIT"
echo "$APP"
