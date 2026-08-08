#!/usr/bin/env bash
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP="$ROOT_DIR/build/MediaBridgeProbe.app"
readonly CODESIGN_INFO="$ROOT_DIR/build/media-bridge-probe-codesign.txt"
readonly ENTITLEMENTS_OUT="$ROOT_DIR/build/media-bridge-probe-entitlements.plist"
readonly ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"

if ! test -d "$APP"; then
  echo "Missing probe bundle: $APP" >&2
  exit 1
fi

codesign --verify --deep --strict "$APP"
codesign -dv --verbose=4 "$APP" 2> "$CODESIGN_INFO"
grep -Eq 'flags=.*runtime' "$CODESIGN_INFO"
codesign --display --entitlements - --xml "$APP" > "$ENTITLEMENTS_OUT"

python3 - "$ENTITLEMENTS_OUT" <<'PY'
import pathlib
import plistlib
import sys

path = pathlib.Path(sys.argv[1])
with path.open("rb") as stream:
    entitlements = plistlib.load(stream)
expected = {"com.apple.security.app-sandbox": True}
if entitlements != expected:
    raise SystemExit(f"unexpected probe entitlements: {entitlements!r}")
PY

INFO_PLIST="$APP/Contents/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")" \
  = "ru.trueruslan.notchhub.media-bridge-probe"
test "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$INFO_PLIST")" = "14.0"
test "$(/usr/libexec/PlistBuddy -c 'Print :ProbeAdapterCommit' "$INFO_PLIST")" \
  = "$ADAPTER_COMMIT"
SOURCE_COMMIT="$(/usr/libexec/PlistBuddy -c 'Print :ProbeSourceCommit' "$INFO_PLIST")"
if [[ ! "$SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Probe source provenance is not a full Git SHA: $SOURCE_COMMIT" >&2
  exit 1
fi

for required in \
  "$APP/Contents/MacOS/MediaBridgeProbe" \
  "$APP/Contents/Resources/mediaremote-adapter.pl" \
  "$APP/Contents/Resources/MediaRemoteAdapter.framework" \
  "$APP/Contents/Resources/MediaRemoteAdapterTestClient" \
  "$APP/Contents/Resources/MediaRemoteAdapter-LICENSE.txt"; do
  test -e "$required"
done

bash "$ROOT_DIR/scripts/build-app.sh" release

if find "$ROOT_DIR/build/NotchHub.app" -type f \( \
  -name 'MediaBridgeProbe' -o \
  -name 'mediaremote-adapter.pl' -o \
  -name 'MediaRemoteAdapterTestClient' \
\) -print -quit | grep -q .; then
  echo "Shipping NotchHub.app contains media probe files" >&2
  exit 1
fi

if find "$ROOT_DIR/build/NotchHub.app" -type d \
  -name 'MediaRemoteAdapter.framework' -print -quit | grep -q .; then
  echo "Shipping NotchHub.app contains MediaRemoteAdapter.framework" >&2
  exit 1
fi

printf 'Media bridge probe verification passed.\n'
