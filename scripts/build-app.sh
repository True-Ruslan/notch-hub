#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_DIR="$ROOT_DIR/build/NotchHub.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
VERSION_FILE="$ROOT_DIR/VERSION"
ENTITLEMENTS_FILE="$ROOT_DIR/Resources/NotchHub.entitlements"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
SOURCE_COMMIT="${SOURCE_COMMIT:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"

readonly MEDIA_BUILD_ROOT="$ROOT_DIR/build/media-bridge-probe"
readonly MEDIA_VENDOR_SOURCE="$MEDIA_BUILD_ROOT/vendor/source"
readonly MEDIA_ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
readonly MEDIA_PATCH_FILE="$ROOT_DIR/Tools/MediaBridgeProbe/patches/mediaremote-adapter-capabilities.patch"
readonly MEDIA_PATCH_SHA256="$(shasum -a 256 "$MEDIA_PATCH_FILE" | awk '{print $1}')"
readonly MEDIA_FRAMEWORK_SOURCE="$MEDIA_VENDOR_SOURCE/build/MediaRemoteAdapter.framework"
readonly MEDIA_SCRIPT_SOURCE="$MEDIA_VENDOR_SOURCE/bin/mediaremote-adapter.pl"
readonly MEDIA_LICENSE_SOURCE="$MEDIA_VENDOR_SOURCE/LICENSE"
readonly MEDIA_FRAMEWORK_DEST="$RESOURCES_DIR/MediaRemoteAdapter.framework"
readonly MEDIA_PROVENANCE_DEST="$RESOURCES_DIR/media-transport-provenance.json"

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

if [[ ! "$SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
    echo "SOURCE_COMMIT must be a lowercase full commit SHA" >&2
    exit 1
fi

if [[ ! "$MEDIA_PATCH_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Invalid media adapter patch SHA-256" >&2
    exit 1
fi

cd "$ROOT_DIR"
# Build only the shipping product. Explicit dead stripping prevents dev-only symbols from
# executable products sharing package targets from inflating NotchHub.app.
swift build -c "$CONFIGURATION" --product NotchHub -Xlinker -dead_strip
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

bash "$ROOT_DIR/scripts/bootstrap-media-bridge-probe.sh"
test "$(git -C "$MEDIA_VENDOR_SOURCE" rev-parse HEAD)" = "$MEDIA_ADAPTER_COMMIT"
git -C "$MEDIA_VENDOR_SOURCE" diff --check
git -C "$MEDIA_VENDOR_SOURCE" apply --reverse --check "$MEDIA_PATCH_FILE"
test -d "$MEDIA_FRAMEWORK_SOURCE"
test -f "$MEDIA_SCRIPT_SOURCE"
test -f "$MEDIA_LICENSE_SOURCE"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_DIR/NotchHub" "$MACOS_DIR/NotchHub"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$MEDIA_SCRIPT_SOURCE" "$RESOURCES_DIR/mediaremote-adapter.pl"
cp -R "$MEDIA_FRAMEWORK_SOURCE" "$MEDIA_FRAMEWORK_DEST"
cp "$MEDIA_LICENSE_SOURCE" "$RESOURCES_DIR/MediaRemoteAdapter-LICENSE.txt"
chmod +x "$MACOS_DIR/NotchHub"

plutil -replace CFBundleShortVersionString -string "$APP_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"
plutil -replace NHSourceCommit -string "$SOURCE_COMMIT" "$CONTENTS_DIR/Info.plist"
plutil -replace NHAdapterCommit -string "$MEDIA_ADAPTER_COMMIT" "$CONTENTS_DIR/Info.plist"
plutil -replace NHAdapterPatchSHA256 -string "$MEDIA_PATCH_SHA256" "$CONTENTS_DIR/Info.plist"

python3 - "$MEDIA_PROVENANCE_DEST" "$SOURCE_COMMIT" "$MEDIA_ADAPTER_COMMIT" "$MEDIA_PATCH_SHA256" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = {
    "schemaVersion": 1,
    "sourceCommit": sys.argv[2],
    "adapterCommit": sys.argv[3],
    "adapterPatchSHA256": sys.argv[4],
}
path.write_text(json.dumps(data, sort_keys=True, indent=2) + "\n", encoding="utf-8")
PY

plutil -lint "$CONTENTS_DIR/Info.plist" >/dev/null
plutil -lint "$ENTITLEMENTS_FILE" >/dev/null
grep -q 'capabilities' "$RESOURCES_DIR/mediaremote-adapter.pl"
nm -gU \
    "$MEDIA_FRAMEWORK_DEST/Versions/A/MediaRemoteAdapter" \
    | grep -q '_adapter_capabilities$'

if command -v codesign >/dev/null 2>&1; then
    nested_sign_args=(
        --force
        --sign "$SIGN_IDENTITY"
    )
    sign_args=(
        --force
        --options runtime
        --entitlements "$ENTITLEMENTS_FILE"
        --sign "$SIGN_IDENTITY"
    )

    if [[ "$SIGN_IDENTITY" != "-" ]]; then
        nested_sign_args+=(--timestamp)
        sign_args+=(--timestamp)
    fi

    codesign "${nested_sign_args[@]}" "$MEDIA_FRAMEWORK_DEST"
    codesign "${sign_args[@]}" "$APP_DIR"
fi

echo "Built $APP_DIR (version $APP_VERSION, build $BUILD_NUMBER, signer $SIGN_IDENTITY)"
echo "Source commit: $SOURCE_COMMIT"
echo "Media adapter commit: $MEDIA_ADAPTER_COMMIT"
echo "Media adapter patch SHA-256: $MEDIA_PATCH_SHA256"
