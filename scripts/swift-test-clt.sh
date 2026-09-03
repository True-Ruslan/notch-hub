#!/bin/sh
# Runs `swift test` using only Xcode Command Line Tools (no full Xcode.app
# install required). CLT ships Testing.framework/lib_TestingInterop.dylib but
# SwiftPM doesn't wire their search paths automatically, so this script does:
#   1. build the test bundle with an extra -F pointing at CLT's Frameworks dir;
#   2. invoke swiftpm-testing-helper directly (bypassing `swift test`'s driver,
#      which strips DYLD_* env vars before spawning the helper) with
#      DYLD_FRAMEWORK_PATH/DYLD_LIBRARY_PATH set so the runtime dylibs resolve.
#
# Usage: scripts/swift-test-clt.sh [--filter <TestName>]

set -eu

CLT_FRAMEWORKS="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
CLT_LIB="/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
HELPER="/Library/Developer/CommandLineTools/usr/libexec/swift/pm/swiftpm-testing-helper"
BUNDLE=".build/arm64-apple-macosx/debug/NotchHubPackageTests.xctest/Contents/MacOS/NotchHubPackageTests"

swift build --build-tests -Xswiftc -F -Xswiftc "$CLT_FRAMEWORKS"

DYLD_FRAMEWORK_PATH="$CLT_FRAMEWORKS" \
DYLD_LIBRARY_PATH="$CLT_LIB" \
"$HELPER" \
  --test-bundle-path "$BUNDLE" \
  "$@" \
  "$BUNDLE" \
  --testing-library swift-testing
