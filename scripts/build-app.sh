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
LINK_MAP_PATH="$ROOT_DIR/build/NotchHub.linkmap"

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
mkdir -p "$ROOT_DIR/build"

if [[ "$CONFIGURATION" == "release" ]]; then
    rm -f "$LINK_MAP_PATH"
    swift build -c "$CONFIGURATION" \
        -Xlinker -map \
        -Xlinker "$LINK_MAP_PATH"
else
    swift build -c "$CONFIGURATION"
fi

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

if [[ "$CONFIGURATION" == "release" && -f "$LINK_MAP_PATH" ]]; then
    python3 - "$LINK_MAP_PATH" <<'PY'
import re
import sys
from collections import defaultdict
from pathlib import Path

path = Path(sys.argv[1])
objects = {}
sizes = defaultdict(int)
section = None

object_pattern = re.compile(r"^\[\s*(\d+)\]\s+(.+)$")
symbol_pattern = re.compile(r"^0x[0-9A-Fa-f]+\s+0x([0-9A-Fa-f]+)\s+\[\s*(\d+)\]\s+")

for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
    if line == "# Object files:":
        section = "objects"
        continue
    if line == "# Symbols:":
        section = "symbols"
        continue
    if line.startswith("# Dead Stripped Symbols:"):
        section = None
        continue
    if line.startswith("# ") and section in {"objects", "symbols"}:
        continue

    if section == "objects":
        match = object_pattern.match(line)
        if match:
            objects[int(match.group(1))] = match.group(2)
    elif section == "symbols":
        match = symbol_pattern.match(line)
        if match:
            sizes[int(match.group(2))] += int(match.group(1), 16)

print("=== NotchHub release link-map object contribution (top 20) ===")
for index, size in sorted(sizes.items(), key=lambda item: item[1], reverse=True)[:20]:
    object_path = objects.get(index, f"object[{index}]")
    print(f"{size:8d} B  {object_path}")
PY
fi

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
        --options runtime
        --entitlements "$ENTITLEMENTS_FILE"
        --sign "$SIGN_IDENTITY"
    )

    if [[ "$SIGN_IDENTITY" != "-" ]]; then
        sign_args+=(--timestamp)
    fi

    # Sign only the top-level app. If nested code is introduced later, sign it
    # explicitly from the innermost component outward before signing the app.
    codesign "${sign_args[@]}" "$APP_DIR"
fi

echo "Built $APP_DIR (version $APP_VERSION, build $BUILD_NUMBER, signer $SIGN_IDENTITY)"
