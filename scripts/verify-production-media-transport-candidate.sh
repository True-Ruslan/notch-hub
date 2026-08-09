#!/usr/bin/env bash
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP="${APP:-$ROOT_DIR/build/ProductionMediaTransportCandidate.app}"
readonly CODESIGN_INFO="$ROOT_DIR/build/production-media-transport-codesign.txt"
readonly ENTITLEMENTS_OUT="$ROOT_DIR/build/production-media-transport-entitlements.plist"
readonly ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
readonly PATCH_FILE="$ROOT_DIR/Tools/MediaBridgeProbe/patches/mediaremote-adapter-capabilities.patch"
readonly PATCH_SHA256="$(shasum -a 256 "$PATCH_FILE" | awk '{print $1}')"
readonly INFO_PLIST="$APP/Contents/Info.plist"
readonly EXECUTABLE="$APP/Contents/MacOS/MediaTransportCandidate"
readonly RESOURCES_DIR="$APP/Contents/Resources"
readonly PROVENANCE="$RESOURCES_DIR/production-media-transport-provenance.json"
readonly ACCEPTANCE_TOOL="$ROOT_DIR/scripts/production_media_transport_acceptance.py"
readonly PREFLIGHT_SMOKE="$ROOT_DIR/build/production-media-transport-preflight-smoke.json"
readonly OBSERVE_SMOKE="$ROOT_DIR/build/production-media-transport-observe-smoke.json"

if ! test -d "$APP"; then
  echo "Missing production media transport candidate bundle: $APP" >&2
  exit 1
fi

for required in \
  "$EXECUTABLE" \
  "$INFO_PLIST" \
  "$RESOURCES_DIR/mediaremote-adapter.pl" \
  "$RESOURCES_DIR/MediaRemoteAdapter.framework" \
  "$RESOURCES_DIR/MediaRemoteAdapter-LICENSE.txt" \
  "$PROVENANCE" \
  "$ACCEPTANCE_TOOL"; do
  test -e "$required"
done

if find "$APP" -type f -name 'MediaRemoteAdapterTestClient' -print -quit | grep -q .; then
  echo "Production media transport candidate contains MediaRemoteAdapterTestClient" >&2
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
    raise SystemExit(f"unexpected candidate entitlements: {entitlements!r}")
PY

test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")" \
  = "ru.trueruslan.notchhub.media-transport-candidate"
test "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$INFO_PLIST")" = "14.0"
test "$(/usr/libexec/PlistBuddy -c 'Print :NHAdapterCommit' "$INFO_PLIST")" = "$ADAPTER_COMMIT"
test "$(/usr/libexec/PlistBuddy -c 'Print :NHAdapterPatchSHA256' "$INFO_PLIST")" \
  = "$PATCH_SHA256"
ACTUAL_SOURCE_COMMIT="$(/usr/libexec/PlistBuddy -c 'Print :NHSourceCommit' "$INFO_PLIST")"
if [[ ! "$ACTUAL_SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Candidate source provenance is not a full Git SHA: $ACTUAL_SOURCE_COMMIT" >&2
  exit 1
fi
if [[ ! "$PATCH_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Candidate adapter patch provenance is not SHA-256: $PATCH_SHA256" >&2
  exit 1
fi
if [[ -n "${SOURCE_COMMIT:-}" ]] && test "$ACTUAL_SOURCE_COMMIT" != "$SOURCE_COMMIT"; then
  echo "Candidate source provenance mismatch" >&2
  exit 1
fi

python3 - "$PROVENANCE" "$ACTUAL_SOURCE_COMMIT" "$ADAPTER_COMMIT" "$PATCH_SHA256" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
expected = {
    "schemaVersion": 1,
    "sourceCommit": sys.argv[2],
    "adapterCommit": sys.argv[3],
    "adapterPatchSHA256": sys.argv[4],
}
if data != expected:
    raise SystemExit(f"unexpected production media transport provenance: {data!r}")
PY

grep -q 'capabilities' "$RESOURCES_DIR/mediaremote-adapter.pl"
nm -gU \
  "$RESOURCES_DIR/MediaRemoteAdapter.framework/Versions/A/MediaRemoteAdapter" \
  | grep -q '_adapter_capabilities$'

otool -L "$EXECUTABLE" | tail -n +2 | awk '{print $1}' | while read -r library; do
  case "$library" in
    /System/*|/usr/lib/*) ;;
    *) echo "Unexpected candidate dynamic library: $library" >&2; exit 1 ;;
  esac
done

python3 "$ACCEPTANCE_TOOL" preflight \
  --app "$APP" \
  --source-commit "$ACTUAL_SOURCE_COMMIT" \
  --output "$PREFLIGHT_SMOKE"

python3 "$ACCEPTANCE_TOOL" observe \
  --app "$APP" \
  --source-commit "$ACTUAL_SOURCE_COMMIT" \
  --seconds 1 \
  --output "$OBSERVE_SMOKE"

bash "$ROOT_DIR/scripts/build-app.sh" release
if find "$ROOT_DIR/build/NotchHub.app" -type f \( \
  -name 'MediaTransportCandidate' -o \
  -name 'mediaremote-adapter.pl' -o \
  -name 'MediaRemoteAdapterTestClient' \
\) -print -quit | grep -q .; then
  echo "Shipping NotchHub.app contains production media transport candidate files" >&2
  exit 1
fi
if find "$ROOT_DIR/build/NotchHub.app" -type d \
  -name 'MediaRemoteAdapter.framework' -print -quit | grep -q .; then
  echo "Shipping NotchHub.app contains MediaRemoteAdapter.framework" >&2
  exit 1
fi

printf 'Production media transport candidate verification passed.\n'
printf 'Source commit: %s\n' "$ACTUAL_SOURCE_COMMIT"
printf 'Adapter commit: %s\n' "$ADAPTER_COMMIT"
printf 'Adapter capability patch SHA-256: %s\n' "$PATCH_SHA256"
