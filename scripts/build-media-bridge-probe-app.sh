#!/usr/bin/env bash
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BUILD_ROOT="$ROOT_DIR/build/media-bridge-probe"
readonly VENDOR_SOURCE="$BUILD_ROOT/vendor/source"
readonly ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
readonly FRAMEWORK_SOURCE="$VENDOR_SOURCE/build/MediaRemoteAdapter.framework"
readonly TEST_CLIENT_SOURCE="$VENDOR_SOURCE/build/MediaRemoteAdapterTestClient"
readonly SCRIPT_SOURCE="$VENDOR_SOURCE/bin/mediaremote-adapter.pl"
readonly LICENSE_SOURCE="$VENDOR_SOURCE/LICENSE"
readonly APP="$ROOT_DIR/build/MediaBridgeProbe.app"
readonly CONTENTS="$APP/Contents"
readonly MACOS_DIR="$CONTENTS/MacOS"
readonly RESOURCES_DIR="$CONTENTS/Resources"
readonly ENTITLEMENTS="$ROOT_DIR/Resources/NotchHub.entitlements"

SOURCE_COMMIT="${SOURCE_COMMIT:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
if [[ ! "$SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Invalid source commit: $SOURCE_COMMIT" >&2
  exit 1
fi

bash "$ROOT_DIR/scripts/bootstrap-media-bridge-probe.sh"
test "$(git -C "$VENDOR_SOURCE" rev-parse HEAD)" = "$ADAPTER_COMMIT"

swift build \
  --package-path "$ROOT_DIR" \
  -c release \
  --product MediaBridgeProbe \
  -Xswiftc -warnings-as-errors

BIN_DIR="$(swift build --package-path "$ROOT_DIR" -c release --show-bin-path)"
PROBE_BINARY="$BIN_DIR/MediaBridgeProbe"
test -x "$PROBE_BINARY"

rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$PROBE_BINARY" "$MACOS_DIR/MediaBridgeProbe"
cp "$SCRIPT_SOURCE" "$RESOURCES_DIR/mediaremote-adapter.pl"
cp -R "$FRAMEWORK_SOURCE" "$RESOURCES_DIR/MediaRemoteAdapter.framework"
cp "$TEST_CLIENT_SOURCE" "$RESOURCES_DIR/MediaRemoteAdapterTestClient"
cp "$LICENSE_SOURCE" "$RESOURCES_DIR/MediaRemoteAdapter-LICENSE.txt"
chmod 0755 "$MACOS_DIR/MediaBridgeProbe" "$RESOURCES_DIR/MediaRemoteAdapterTestClient"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MediaBridgeProbe</string>
  <key>CFBundleIdentifier</key>
  <string>ru.trueruslan.notchhub.media-bridge-probe</string>
  <key>CFBundleName</key>
  <string>MediaBridgeProbe</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>ProbeSourceCommit</key>
  <string>$SOURCE_COMMIT</string>
  <key>ProbeAdapterCommit</key>
  <string>$ADAPTER_COMMIT</string>
</dict>
</plist>
PLIST

plutil -lint "$CONTENTS/Info.plist" >/dev/null

codesign --force --sign - "$RESOURCES_DIR/MediaRemoteAdapter.framework"
codesign --force --sign - "$RESOURCES_DIR/MediaRemoteAdapterTestClient"
codesign --force --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign - "$APP"

printf 'Built %s\n' "$APP"
