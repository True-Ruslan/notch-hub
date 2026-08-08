#!/usr/bin/env bash
set -euo pipefail

readonly ADAPTER_REPO="https://github.com/ungive/mediaremote-adapter.git"
readonly ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly VENDOR_DIR="$ROOT_DIR/build/media-bridge-probe/vendor"
readonly SOURCE_DIR="$VENDOR_DIR/source"
readonly BUILD_DIR="$SOURCE_DIR/build"
readonly FRAMEWORK="$BUILD_DIR/MediaRemoteAdapter.framework"
readonly TEST_CLIENT="$FRAMEWORK/Versions/A/Support/MediaRemoteAdapterTestClient"
readonly ADAPTER_SCRIPT="$SOURCE_DIR/bin/mediaremote-adapter.pl"
readonly LICENSE_FILE="$SOURCE_DIR/LICENSE"

has_exact_source() {
  test -d "$SOURCE_DIR/.git" \
    && test "$(git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null || true)" = "$ADAPTER_COMMIT"
}

has_required_assets() {
  test -d "$FRAMEWORK" \
    && test -f "$TEST_CLIENT" \
    && test -f "$ADAPTER_SCRIPT" \
    && test -f "$LICENSE_FILE"
}

mkdir -p "$VENDOR_DIR"

if ! has_exact_source; then
  rm -rf "$SOURCE_DIR"
  git init -q "$SOURCE_DIR"
  git -C "$SOURCE_DIR" remote add origin "$ADAPTER_REPO"
  git -C "$SOURCE_DIR" fetch -q --depth 1 origin "$ADAPTER_COMMIT"
  git -C "$SOURCE_DIR" checkout -q --detach FETCH_HEAD
fi

test "$(git -C "$SOURCE_DIR" rev-parse HEAD)" = "$ADAPTER_COMMIT"

if ! has_required_assets; then
  cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$BUILD_DIR" --config Release
fi

has_required_assets

printf 'Media bridge probe adapter ready at %s\n' "$VENDOR_DIR"
printf 'Adapter commit: %s\n' "$ADAPTER_COMMIT"
