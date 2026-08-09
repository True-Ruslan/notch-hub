#!/usr/bin/env bash
set -euo pipefail

readonly ADAPTER_REPO="https://github.com/ungive/mediaremote-adapter.git"
readonly ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PATCH_FILE="$ROOT_DIR/Tools/MediaBridgeProbe/patches/mediaremote-adapter-capabilities.patch"
readonly PATCH_SHA256="$(shasum -a 256 "$PATCH_FILE" | awk '{print $1}')"
readonly VENDOR_DIR="$ROOT_DIR/build/media-bridge-probe/vendor"
readonly SOURCE_DIR="$VENDOR_DIR/source"
readonly BUILD_DIR="$SOURCE_DIR/build"
readonly FRAMEWORK="$BUILD_DIR/MediaRemoteAdapter.framework"
readonly TEST_CLIENT="$BUILD_DIR/MediaRemoteAdapterTestClient"
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
test -f "$PATCH_FILE"
test "$PATCH_SHA256" != ""

if ! has_exact_source; then
  rm -rf "$SOURCE_DIR"
  git init -q "$SOURCE_DIR"
  git -C "$SOURCE_DIR" remote add origin "$ADAPTER_REPO"
  git -C "$SOURCE_DIR" fetch -q --depth 1 origin "$ADAPTER_COMMIT"
  git -C "$SOURCE_DIR" checkout -q --detach FETCH_HEAD
fi

test "$(git -C "$SOURCE_DIR" rev-parse HEAD)" = "$ADAPTER_COMMIT"

# Every probe build starts from the exact pinned upstream tree. This makes the
# repo-owned patch, rather than leftover local state, the only source delta.
git -C "$SOURCE_DIR" reset --hard -q "$ADAPTER_COMMIT"
git -C "$SOURCE_DIR" clean -fdx -q
git -C "$SOURCE_DIR" apply --check "$PATCH_FILE"
git -C "$SOURCE_DIR" apply "$PATCH_FILE"

if ! command -v cmake >/dev/null 2>&1; then
  echo "Media bridge probe bootstrap requires CMake to build the pinned adapter." >&2
  exit 1
fi

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" --config Release

has_required_assets

test "$(git -C "$SOURCE_DIR" rev-parse HEAD)" = "$ADAPTER_COMMIT"
test -n "$(git -C "$SOURCE_DIR" status --porcelain)"

printf 'Media bridge probe adapter ready at %s\n' "$VENDOR_DIR"
printf 'Adapter commit: %s\n' "$ADAPTER_COMMIT"
printf 'Adapter capability patch SHA-256: %s\n' "$PATCH_SHA256"
