#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_SOURCE_COMMIT="fdbe987d8f22768b2a75406c8f1e721fa1da2845"
EXPECTED_DMG_SHA256="6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd"

usage() {
  cat <<'EOF'
Usage:
  scripts/run-shipping-media-target-acceptance.sh \
    --dmg PATH [--output-dir PATH] [--run-mode compact-full|expanded-steady]

Runs the frozen lazy-lifecycle M6.4 shipping candidate on the target Mac.

Run modes:
  compact-full     Default background acceptance. Keep the panel compact and
                   untouched. Measures 60-second steady + 10-minute stability
                   and fails if any owned media adapter appears.
  expanded-steady  Active feature-cost acceptance. The script launches compact,
                   then asks you to hover until the panel is visibly expanded
                   and press Return. Keep the pointer inside the expanded panel
                   for the 60-second measurement. Exactly one owned adapter is
                   required and normal application termination must release it.
EOF
}

DMG_INPUT=""
OUTPUT_DIR="$ROOT_DIR/build/m6-4-target-acceptance"
RUN_MODE="compact-full"
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
    --run-mode)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      case "$2" in
        compact-full|expanded-steady)
          RUN_MODE="$2"
          ;;
        *)
          echo "Invalid run mode: $2" >&2
          usage >&2
          exit 2
          ;;
      esac
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
  echo "Unexpected M6.4 DMG SHA-256: $ACTUAL_DMG_SHA256" >&2
  echo "Expected: $EXPECTED_DMG_SHA256" >&2
  exit 1
fi

MOUNT_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/notchhub-m6-4-mount.XXXXXX")"
TERMINATOR_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/notchhub-m6-4-terminate.XXXXXX")"
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

wait_for_parent_exit() {
  local deadline=$((SECONDS + 10))
  while /bin/ps -p "$APP_PID" -o pid= >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
      echo "NotchHub did not terminate within the bounded 10-second window" >&2
      return 1
    fi
    /bin/sleep 0.1
  done
}

/usr/bin/hdiutil attach "$DMG_PATH" -readonly -nobrowse -mountpoint "$MOUNT_DIR" >/dev/null
MOUNTED=1
APP="$MOUNT_DIR/NotchHub.app"
[[ -d "$APP" ]] || { echo "Mounted DMG does not contain NotchHub.app" >&2; exit 1; }

python3 "$ROOT_DIR/scripts/shipping_media_acceptance.py" preflight \
  --app "$APP" \
  --source-commit "$EXPECTED_SOURCE_COMMIT" \
  --output "$OUTPUT_DIR/preflight.json"

if /usr/bin/pgrep -x NotchHub >/dev/null 2>&1; then
  echo "A NotchHub process is already running. Quit it before acceptance." >&2
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

if [[ "$RUN_MODE" == "compact-full" ]]; then
  echo "Compact acceptance: keep the panel untouched for the complete run."

  python3 "$ROOT_DIR/scripts/shipping_media_compact_acceptance.py" \
    --attach-pid "$APP_PID" \
    --source-commit "$EXPECTED_SOURCE_COMMIT" \
    --mode steady \
    --output "$OUTPUT_DIR/compact-steady.json"

  python3 "$ROOT_DIR/scripts/shipping_media_compact_acceptance.py" \
    --attach-pid "$APP_PID" \
    --source-commit "$EXPECTED_SOURCE_COMMIT" \
    --mode stability \
    --output "$OUTPUT_DIR/compact-stability.json"

  "$TERMINATOR_BIN" "$APP_PID"
  wait_for_parent_exit
  APP_PID=""

  python3 - "$OUTPUT_DIR" "$EXPECTED_SOURCE_COMMIT" "$RUN_MODE" <<'PY'
from __future__ import annotations

import json
import pathlib
import sys

output_dir = pathlib.Path(sys.argv[1])
source_commit = sys.argv[2]
run_mode = sys.argv[3]
reports = {
    name: json.loads((output_dir / f"{name}.json").read_text(encoding="utf-8"))
    for name in ("preflight", "compact-steady", "compact-stability")
}
for name, report in reports.items():
    if report.get("sourceCommit") != source_commit:
        raise SystemExit(f"{name} source provenance mismatch")

steady = reports["compact-steady"]
stability = reports["compact-stability"]
for name, report in (("steady", steady), ("stability", stability)):
    if report.get("resourceScope") != "compact-parent-only":
        raise SystemExit(f"{name} is not compact-parent-only evidence")
    if report.get("adapterAbsent") is not True:
        raise SystemExit(f"{name} observed an unexpected media adapter")

if steady.get("sampleCount") != 60:
    raise SystemExit("compact steady acceptance must contain exactly 60 samples")
if stability.get("sampleCount") != 120:
    raise SystemExit("compact stability acceptance must contain exactly 120 samples")

summary = {
    "schemaVersion": 1,
    "sourceCommit": source_commit,
    "runMode": run_mode,
    "resourceScope": "compact-parent-only",
    "preflightVerified": True,
    "adapterAbsent": True,
    "steadySampleCount": steady["sampleCount"],
    "stabilitySampleCount": stability["sampleCount"],
    "parentExited": True,
}
(output_dir / "summary.json").write_text(
    json.dumps(summary, sort_keys=True, indent=2) + "\n",
    encoding="utf-8",
)
PY

  cat "$OUTPUT_DIR/preflight.json"
  cat "$OUTPUT_DIR/compact-steady.json"
  cat "$OUTPUT_DIR/compact-stability.json"
  cat "$OUTPUT_DIR/summary.json"
else
  echo "Waiting for settled expanded media runtime."
  echo "Hover over the notch until the panel is visibly expanded, keep the pointer inside it, then press Return here."
  IFS= read -r _

  python3 "$ROOT_DIR/scripts/shipping_media_acceptance.py" resources \
    --attach-pid "$APP_PID" \
    --source-commit "$EXPECTED_SOURCE_COMMIT" \
    --mode steady \
    --output "$OUTPUT_DIR/steady.json"

  python3 "$ROOT_DIR/scripts/shipping_media_acceptance.py" teardown \
    --attach-pid "$APP_PID" \
    --source-commit "$EXPECTED_SOURCE_COMMIT" \
    --timeout-seconds 60 \
    --output "$OUTPUT_DIR/teardown.json" &
  TEARDOWN_COLLECTOR_PID=$!

  /bin/sleep 1
  "$TERMINATOR_BIN" "$APP_PID"
  wait "$TEARDOWN_COLLECTOR_PID"
  APP_PID=""

  python3 - "$OUTPUT_DIR" "$EXPECTED_SOURCE_COMMIT" "$RUN_MODE" <<'PY'
from __future__ import annotations

import json
import pathlib
import sys

output_dir = pathlib.Path(sys.argv[1])
source_commit = sys.argv[2]
run_mode = sys.argv[3]
reports = {
    name: json.loads((output_dir / f"{name}.json").read_text(encoding="utf-8"))
    for name in ("preflight", "steady", "teardown")
}
for name, report in reports.items():
    if report.get("sourceCommit") != source_commit:
        raise SystemExit(f"{name} source provenance mismatch")
if reports["steady"].get("sampleCount") != 60:
    raise SystemExit("expanded steady acceptance must contain exactly 60 samples")

teardown = reports["teardown"]
if teardown.get("parentExited") is not True:
    raise SystemExit("NotchHub did not terminate normally")
if teardown.get("adapterExited") is not True:
    raise SystemExit("owned media adapter did not terminate")
if teardown.get("orphanProcessDetected") is not False:
    raise SystemExit("orphan media adapter process detected")

summary = {
    "schemaVersion": 1,
    "sourceCommit": source_commit,
    "runMode": run_mode,
    "preflightVerified": True,
    "steadySampleCount": reports["steady"]["sampleCount"],
    "parentExited": True,
    "adapterExited": True,
    "orphanProcessDetected": False,
}
(output_dir / "summary.json").write_text(
    json.dumps(summary, sort_keys=True, indent=2) + "\n",
    encoding="utf-8",
)
PY

  cat "$OUTPUT_DIR/preflight.json"
  cat "$OUTPUT_DIR/steady.json"
  cat "$OUTPUT_DIR/teardown.json"
  cat "$OUTPUT_DIR/summary.json"
fi

echo "M6.4 target-Mac evidence written to: $OUTPUT_DIR"
