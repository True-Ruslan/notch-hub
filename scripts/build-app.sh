#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_DIR="$ROOT_DIR/build/NotchHub.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
VERSION_FILE="$ROOT_DIR/VERSION"
ENTITLEMENTS_FILE="$ROOT_DIR/Resources/NotchHub.entitlements"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Missing VERSION file" >&2
    exit 1
fi

if [[ ! -f "$ENTITLEMENTS_FILE" ]]; then
    echo "Missing entitlements file: $ENTITLEMENTS_FILE" >&2
    exit 1
fi

APP_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

if [[ ! "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Invalid semantic version in VERSION: $APP_VERSION" >&2
    exit 1
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || [[ "$BUILD_NUMBER" == "0" ]]; then
    echo "BUILD_NUMBER must be a positive integer" >&2
    exit 1
fi

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$BIN_DIR/NotchHub" "$MACOS_DIR/NotchHub"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/NotchHub"

plutil -replace CFBundleShortVersionString -string "$APP_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"

if command -v codesign >/dev/null 2>&1; then
    sign_args=(
        --force
        --deep
        --options runtime
        --entitlements "$ENTITLEMENTS_FILE"
        --sign "$SIGN_IDENTITY"
    )

    if [[ "$SIGN_IDENTITY" != "-" ]]; then
        sign_args+=(--timestamp)
    fi

    codesign "${sign_args[@]}" "$APP_DIR"
fi

echo "Built $APP_DIR (version $APP_VERSION, build $BUILD_NUMBER, signer $SIGN_IDENTITY)"
