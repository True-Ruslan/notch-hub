#!/usr/bin/env bash
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BUILD_ROOT="$ROOT_DIR/build/media-bridge-probe"
readonly VENDOR_SOURCE="$BUILD_ROOT/vendor/source"
readonly ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
readonly PATCH_FILE="$ROOT_DIR/Tools/MediaBridgeProbe/patches/mediaremote-adapter-capabilities.patch"
readonly PATCH_SHA256="$(shasum -a 256 "$PATCH_FILE" | awk '{print $1}')"
readonly FRAMEWORK_SOURCE="$VENDOR_SOURCE/build/MediaRemoteAdapter.framework"
readonly SCRIPT_SOURCE="$VENDOR_SOURCE/bin/mediaremote-adapter.pl"
readonly LICENSE_SOURCE="$VENDOR_SOURCE/LICENSE"
readonly APP="$ROOT_DIR/build/ProductionMediaTransportCandidate.app"
readonly CONTENTS="$APP/Contents"
readonly MACOS_DIR="$CONTENTS/MacOS"
readonly RESOURCES_DIR="$CONTENTS/Resources"
readonly ENTITLEMENTS="$ROOT_DIR/Resources/ProductionMediaTransportCandidate.entitlements"
readonly PROVENANCE="$RESOURCES_DIR/production-media-transport-provenance.json"

SOURCE_COMMIT="${SOURCE_COMMIT:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
if [[ ! "$SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Invalid source commit: $SOURCE_COMMIT" >&2
  exit 1
fi
if [[ ! "$PATCH_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Invalid adapter patch SHA-256: $PATCH_SHA256" >&2
  exit 1
fi

test -f "$ENTITLEMENTS"
bash "$ROOT_DIR/scripts/bootstrap-media-bridge-probe.sh"
test "$(git -C "$VENDOR_SOURCE" rev-parse HEAD)" = "$ADAPTER_COMMIT"
git -C "$VENDOR_SOURCE" diff --check
git -C "$VENDOR_SOURCE" apply --reverse --check "$PATCH_FILE"

(
  cd "$ROOT_DIR"
  swift build -c release --product MediaTransportCandidate -Xswiftc -warnings-as-errors
)

BIN_DIR="$(swift build --package-path "$ROOT_DIR" -c release --show-bin-path)"
CANDIDATE_BINARY="$BIN_DIR/MediaTransportCandidate"
test -x "$CANDIDATE_BINARY"
test -d "$FRAMEWORK_SOURCE"
test -f "$SCRIPT_SOURCE"
test -f "$LICENSE_SOURCE"

rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$CANDIDATE_BINARY" "$MACOS_DIR/MediaTransportCandidate"
cp "$SCRIPT_SOURCE" "$RESOURCES_DIR/mediaremote-adapter.pl"
cp -R "$FRAMEWORK_SOURCE" "$RESOURCES_DIR/MediaRemoteAdapter.framework"
cp "$LICENSE_SOURCE" "$RESOURCES_DIR/MediaRemoteAdapter-LICENSE.txt"
chmod 0755 "$MACOS_DIR/MediaTransportCandidate"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MediaTransportCandidate</string>
  <key>CFBundleIdentifier</key>
  <string>ru.trueruslan.notchhub.media-transport-candidate</string>
  <key>CFBundleName</key>
  <string>ProductionMediaTransportCandidate</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NHSourceCommit</key>
  <string>$SOURCE_COMMIT</string>
  <key>NHAdapterCommit</key>
  <string>$ADAPTER_COMMIT</string>
  <key>NHAdapterPatchSHA256</key>
  <string>$PATCH_SHA256</string>
</dict>
</plist>
PLIST

python3 - "$PROVENANCE" "$SOURCE_COMMIT" "$ADAPTER_COMMIT" "$PATCH_SHA256" <<'PY'
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

plutil -lint "$CONTENTS/Info.plist" >/dev/null
plutil -lint "$ENTITLEMENTS" >/dev/null

grep -q 'capabilities' "$RESOURCES_DIR/mediaremote-adapter.pl"
nm -gU \
  "$RESOURCES_DIR/MediaRemoteAdapter.framework/Versions/A/MediaRemoteAdapter" \
  | grep -q '_adapter_capabilities$'

codesign --force --sign - "$RESOURCES_DIR/MediaRemoteAdapter.framework"
codesign --force --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign - "$APP"

printf 'Built %s\n' "$APP"
printf 'Source commit: %s\n' "$SOURCE_COMMIT"
printf 'Adapter commit: %s\n' "$ADAPTER_COMMIT"
printf 'Adapter capability patch SHA-256: %s\n' "$PATCH_SHA256"
