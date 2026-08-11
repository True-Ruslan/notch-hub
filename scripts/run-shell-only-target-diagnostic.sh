#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_SOURCE_COMMIT="30de94c0cb6ea17dc21bd366404937db2bc73783"
EXPECTED_DMG_SHA256="b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7"
EXPECTED_ARTIFACT_ID="9063213178"
EXPECTED_RUN_ID="31389611697"
EXPECTED_BUNDLE_ID="ru.trueruslan.notchhub"

usage() {
  cat <<EOF
Usage:
  scripts/run-shell-only-target-diagnostic.sh \\
    --dmg PATH [--output-dir PATH]

Runs the exact final M6.3 shell-only NotchHub DMG from CI #594 / run
$EXPECTED_RUN_ID / artifact $EXPECTED_ARTIFACT_ID through the same target-Mac
parent-only steady and stability sampler used by M6.4 compact acceptance.
EOF
}

DMG_INPUT=""
OUTPUT_DIR="$ROOT_DIR/build/m6-3-shell-only-diagnostic"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dmg)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      DMG_INPUT="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$DMG_INPUT" ]] || { usage >&2; exit 2; }
[[ -f "$DMG_INPUT" ]] || { echo "DMG does not exist: $DMG_INPUT" >&2; exit 1; }

DMG_DIR="$(cd "$(dirname "$DMG_INPUT")" && pwd -P)"
DMG_PATH="$DMG_DIR/$(basename "$DMG_INPUT")"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd -P)"

ACTUAL_DMG_SHA256="$(/usr/bin/shasum -a 256 "$DMG_PATH" | /usr/bin/awk '{print $1}')"
if [[ "$ACTUAL_DMG_SHA256" != "$EXPECTED_DMG_SHA256" ]]; then
  echo "Unexpected M6.3 shell-only DMG SHA-256: $ACTUAL_DMG_SHA256" >&2
  echo "Expected: $EXPECTED_DMG_SHA256" >&2
  exit 1
fi

MOUNT_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/notchhub-m6-3-shell-mount.XXXXXX")"
TERMINATOR_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/notchhub-m6-3-shell-terminate.XXXXXX")"
TERMINATOR_SOURCE="$TERMINATOR_DIR/TerminateNotchHub.swift"
TERMINATOR_BIN="$TERMINATOR_DIR/terminate-notchhub"
MOUNTED=0
APP_PID=""

cleanup() {
  local status=$?
  trap - EXIT

  if [[ -n "${APP_PID:-}" ]] && /bin/ps -p "$APP_PID" -o pid= >/dev/null 2>&1; then
    if [[ -x "${TERMINATOR_BIN:-}" ]]; then
      "$TERMINATOR_BIN" "$APP_PID" >/dev/null 2>&1 || true
    fi
  fi

  if [[ "${MOUNTED:-0}" -eq 1 ]]; then
    /usr/bin/hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || true
  fi

  /bin/rm -rf "$MOUNT_DIR" "$TERMINATOR_DIR"
  exit "$status"
}
trap cleanup EXIT

/usr/bin/hdiutil attach "$DMG_PATH" -readonly -nobrowse -mountpoint "$MOUNT_DIR" >/dev/null
MOUNTED=1
APP="$MOUNT_DIR/NotchHub.app"
[[ -d "$APP" ]] || { echo "Mounted DMG does not contain NotchHub.app" >&2; exit 1; }

/usr/bin/codesign --verify --deep --strict "$APP"
ACTUAL_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
[[ "$ACTUAL_BUNDLE_ID" == "$EXPECTED_BUNDLE_ID" ]] || {
  echo "Unexpected bundle identifier: $ACTUAL_BUNDLE_ID" >&2
  exit 1
}

for forbidden_resource in \
  mediaremote-adapter.pl \
  MediaRemoteAdapter.framework \
  MediaRemoteAdapter-LICENSE.txt \
  media-transport-provenance.json; do
  if [[ -e "$APP/Contents/Resources/$forbidden_resource" ]]; then
    echo "M6.3 shell-only comparator unexpectedly contains $forbidden_resource" >&2
    exit 1
  fi
done

if /usr/bin/pgrep -x NotchHub >/dev/null 2>&1; then
  echo "A NotchHub process is already running. Quit it before the diagnostic." >&2
  exit 1
fi

cat > "$TERMINATOR_SOURCE" <<'SWIFT'
import AppKit
import Darwin

guard CommandLine.arguments.count == 2,
      let rawPID = Int32(CommandLine.arguments[1]),
      let application = NSRunningApplication(processIdentifier: pid_t(rawPID))
else {
    exit(2)
}

exit(application.terminate() ? 0 : 3)
SWIFT
/usr/bin/xcrun swiftc "$TERMINATOR_SOURCE" -o "$TERMINATOR_BIN"

/usr/bin/open -n "$APP"
for _ in {1..100}; do
  PIDS="$(/usr/bin/pgrep -x NotchHub || true)"
  PID_COUNT="$(printf '%s\n' "$PIDS" | /usr/bin/awk 'NF { count += 1 } END { print count + 0 }')"
  if [[ "$PID_COUNT" -eq 1 ]]; then
    APP_PID="$PIDS"
    break
  fi
  if [[ "$PID_COUNT" -gt 1 ]]; then
    echo "Expected exactly one NotchHub process, found $PID_COUNT" >&2
    exit 1
  fi
  /bin/sleep 0.1
done
[[ -n "$APP_PID" ]] || { echo "NotchHub did not launch within the bounded startup window" >&2; exit 1; }

echo "Shell-only diagnostic: keep the panel untouched for the complete run."
python3 "$ROOT_DIR/scripts/shipping_media_compact_acceptance.py" \
  --attach-pid "$APP_PID" \
  --source-commit "$EXPECTED_SOURCE_COMMIT" \
  --mode steady \
  --output "$OUTPUT_DIR/steady.json"

python3 "$ROOT_DIR/scripts/shipping_media_compact_acceptance.py" \
  --attach-pid "$APP_PID" \
  --source-commit "$EXPECTED_SOURCE_COMMIT" \
  --mode stability \
  --output "$OUTPUT_DIR/stability.json"

"$TERMINATOR_BIN" "$APP_PID"
for _ in {1..600}; do
  if ! /bin/ps -p "$APP_PID" -o pid= >/dev/null 2>&1; then
    APP_PID=""
    break
  fi
  /bin/sleep 0.1
done
[[ -z "$APP_PID" ]] || { echo "Shell-only NotchHub did not exit after normal termination request" >&2; exit 1; }

python3 - "$OUTPUT_DIR" "$EXPECTED_SOURCE_COMMIT" "$EXPECTED_RUN_ID" "$EXPECTED_ARTIFACT_ID" <<'PY'
from __future__ import annotations

import json
import pathlib
import sys

output_dir = pathlib.Path(sys.argv[1])
source_commit = sys.argv[2]
run_id = sys.argv[3]
artifact_id = sys.argv[4]
reports = {
    name: json.loads((output_dir / f"{name}.json").read_text(encoding="utf-8"))
    for name in ("steady", "stability")
}
for name, report in reports.items():
    if report.get("sourceCommit") != source_commit:
        raise SystemExit(f"{name} source provenance mismatch")
    if report.get("resourceScope") != "compact-parent-only":
        raise SystemExit(f"{name} resource scope mismatch")
    if report.get("adapterAbsent") is not True:
        raise SystemExit(f"{name} unexpectedly observed an adapter")

if reports["steady"].get("sampleCount") != 60:
    raise SystemExit("steady diagnostic must contain exactly 60 samples")
if reports["stability"].get("sampleCount") != 120:
    raise SystemExit("stability diagnostic must contain exactly 120 samples")

summary = {
    "schemaVersion": 1,
    "diagnostic": "m6.3-shell-only-comparator",
    "sourceCommit": source_commit,
    "workflowRunId": run_id,
    "artifactId": artifact_id,
    "resourceScope": "compact-parent-only",
    "adapterAbsent": True,
    "parentExited": True,
    "steadySampleCount": 60,
    "stabilitySampleCount": 120,
}
(output_dir / "summary.json").write_text(
    json.dumps(summary, sort_keys=True, indent=2) + "\n",
    encoding="utf-8",
)
PY

cat "$OUTPUT_DIR/steady.json"
cat "$OUTPUT_DIR/stability.json"
cat "$OUTPUT_DIR/summary.json"
echo "M6.3 shell-only target diagnostic written to: $OUTPUT_DIR"
