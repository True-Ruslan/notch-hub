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

if [[ "$CONFIGURATION" == "release" ]]; then
    python3 - "$BIN_DIR/NotchHub" <<'PY'
import re
import subprocess
import sys

binary = sys.argv[1]
raw = subprocess.check_output(["nm", "-n", binary], text=True)
by_address = {}
for line in raw.splitlines():
    match = re.match(r"^([0-9A-Fa-f]+)\s+([A-Za-z])\s+(.+)$", line)
    if not match:
        continue
    address = int(match.group(1), 16)
    kind = match.group(2)
    symbol = match.group(3)
    by_address.setdefault(address, []).append((kind, symbol))

addresses = sorted(by_address)
rows = []
for index, address in enumerate(addresses[:-1]):
    text_symbols = [symbol for kind, symbol in by_address[address] if kind in {"t", "T"}]
    if not text_symbols:
        continue
    next_address = addresses[index + 1]
    size = next_address - address
    if size <= 0:
        continue
    rows.append((size, address, text_symbols[0]))

print("Release top text symbols by address-delta estimate:")
for size, address, symbol in sorted(rows, reverse=True)[:40]:
    demangled = subprocess.check_output(["swift", "demangle", symbol], text=True).strip()
    print(f"{size:8d} B  0x{address:x}  {demangled}")
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
