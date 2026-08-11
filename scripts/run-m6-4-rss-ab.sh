#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_BUNDLE_ID="ru.trueruslan.notchhub"

BASELINE_SOURCE_COMMIT="8e913dcddfdec7d9aa920df8c37afb23b8c40884"
BASELINE_DMG_SHA256="cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc"
BASELINE_RELEASE_ASSET_ID="505235050"

CANDIDATE_SOURCE_COMMIT="fdbe987d8f22768b2a75406c8f1e721fa1da2845"
CANDIDATE_DMG_SHA256="6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd"
CANDIDATE_ARTIFACT_ID="9093958828"
CANDIDATE_RUN_ID="31472420797"

usage() {
  cat <<EOF
Usage:
  scripts/run-m6-4-rss-ab.sh \\
    --baseline-dmg PATH \\
    --candidate-dmg PATH \\
    [--output-dir PATH]

Runs the exact immutable v0.1.0 baseline and frozen M6.4 candidate through one
shared 60-second parent-only steady collector in the same target-Mac session.
Keep the pointer away from the notch for the complete comparison.
EOF
}

BASELINE_DMG_INPUT=""
CANDIDATE_DMG_INPUT=""
OUTPUT_DIR="$ROOT_DIR/build/m6-4-rss-ab"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline-dmg)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      BASELINE_DMG_INPUT="$2"
      shift 2
      ;;
    --candidate-dmg)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      CANDIDATE_DMG_INPUT="$2"
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

[[ -n "$BASELINE_DMG_INPUT" && -n "$CANDIDATE_DMG_INPUT" ]] || { usage >&2; exit 2; }
[[ -f "$BASELINE_DMG_INPUT" ]] || { echo "Baseline DMG does not exist: $BASELINE_DMG_INPUT" >&2; exit 1; }
[[ -f "$CANDIDATE_DMG_INPUT" ]] || { echo "Candidate DMG does not exist: $CANDIDATE_DMG_INPUT" >&2; exit 1; }

BASELINE_DMG_PATH="$(cd "$(dirname "$BASELINE_DMG_INPUT")" && pwd -P)/$(basename "$BASELINE_DMG_INPUT")"
CANDIDATE_DMG_PATH="$(cd "$(dirname "$CANDIDATE_DMG_INPUT")" && pwd -P)/$(basename "$CANDIDATE_DMG_INPUT")"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd -P)"

if /usr/bin/pgrep -x NotchHub >/dev/null 2>&1; then
  echo "A NotchHub process is already running. Quit it before the A/B run." >&2
  exit 1
fi

TERMINATOR_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/notchhub-m6-4-rss-ab-terminate.XXXXXX")"
TERMINATOR_SOURCE="$TERMINATOR_DIR/TerminateNotchHub.swift"
TERMINATOR_BIN="$TERMINATOR_DIR/terminate-notchhub"
CURRENT_MOUNT=""
CURRENT_PID=""

cleanup() {
  local status=$?
  trap - EXIT
  if [[ -n "${CURRENT_PID:-}" ]] && /bin/ps -p "$CURRENT_PID" -o pid= >/dev/null 2>&1; then
    if [[ -x "${TERMINATOR_BIN:-}" ]]; then
      "$TERMINATOR_BIN" "$CURRENT_PID" >/dev/null 2>&1 || true
    fi
  fi
  if [[ -n "${CURRENT_MOUNT:-}" ]]; then
    /usr/bin/hdiutil detach "$CURRENT_MOUNT" -quiet >/dev/null 2>&1 || true
  fi
  /bin/rm -rf "$TERMINATOR_DIR"
  exit "$status"
}
trap cleanup EXIT

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

run_candidate() {
  local label="$1"
  local dmg_path="$2"
  local expected_sha="$3"
  local source_commit="$4"
  local output_json="$5"

  local actual_sha
  actual_sha="$(/usr/bin/shasum -a 256 "$dmg_path" | /usr/bin/awk '{print $1}')"
  if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "Unexpected $label DMG SHA-256: $actual_sha" >&2
    echo "Expected: $expected_sha" >&2
    exit 1
  fi

  CURRENT_MOUNT="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/notchhub-${label}-mount.XXXXXX")"
  /usr/bin/hdiutil attach "$dmg_path" -readonly -nobrowse -mountpoint "$CURRENT_MOUNT" >/dev/null

  local app="$CURRENT_MOUNT/NotchHub.app"
  [[ -d "$app" ]] || { echo "$label DMG does not contain NotchHub.app" >&2; exit 1; }
  /usr/bin/codesign --verify --deep --strict "$app"

  local bundle_id
  bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")"
  [[ "$bundle_id" == "$EXPECTED_BUNDLE_ID" ]] || {
    echo "Unexpected $label bundle identifier: $bundle_id" >&2
    exit 1
  }

  if /usr/bin/pgrep -x NotchHub >/dev/null 2>&1; then
    echo "A NotchHub process is already running before $label launch." >&2
    exit 1
  fi

  /usr/bin/open -n "$app"
  for _ in {1..100}; do
    local pids pid_count
    pids="$(/usr/bin/pgrep -x NotchHub || true)"
    pid_count="$(printf '%s\n' "$pids" | /usr/bin/awk 'NF { count += 1 } END { print count + 0 }')"
    if [[ "$pid_count" -eq 1 ]]; then
      CURRENT_PID="$pids"
      break
    fi
    if [[ "$pid_count" -gt 1 ]]; then
      echo "Expected exactly one NotchHub process for $label, found $pid_count" >&2
      exit 1
    fi
    /bin/sleep 0.1
  done
  [[ -n "$CURRENT_PID" ]] || { echo "$label NotchHub did not launch within the bounded startup window" >&2; exit 1; }

  echo "M6.4 RSS A/B [$label]: keep the panel untouched."
  python3 "$ROOT_DIR/scripts/shipping_media_compact_acceptance.py" \
    --attach-pid "$CURRENT_PID" \
    --source-commit "$source_commit" \
    --mode steady \
    --output "$output_json"

  "$TERMINATOR_BIN" "$CURRENT_PID"
  for _ in {1..600}; do
    if ! /bin/ps -p "$CURRENT_PID" -o pid= >/dev/null 2>&1; then
      CURRENT_PID=""
      break
    fi
    /bin/sleep 0.1
  done
  [[ -z "$CURRENT_PID" ]] || { echo "$label NotchHub did not exit after normal termination request" >&2; exit 1; }

  /usr/bin/hdiutil detach "$CURRENT_MOUNT" -quiet
  CURRENT_MOUNT=""
}

run_candidate \
  "baseline-v0-1-0" \
  "$BASELINE_DMG_PATH" \
  "$BASELINE_DMG_SHA256" \
  "$BASELINE_SOURCE_COMMIT" \
  "$OUTPUT_DIR/baseline-steady.json"

run_candidate \
  "m6-4-frozen" \
  "$CANDIDATE_DMG_PATH" \
  "$CANDIDATE_DMG_SHA256" \
  "$CANDIDATE_SOURCE_COMMIT" \
  "$OUTPUT_DIR/candidate-steady.json"

python3 - \
  "$OUTPUT_DIR" \
  "$BASELINE_SOURCE_COMMIT" \
  "$BASELINE_RELEASE_ASSET_ID" \
  "$CANDIDATE_SOURCE_COMMIT" \
  "$CANDIDATE_RUN_ID" \
  "$CANDIDATE_ARTIFACT_ID" <<'PY'
from __future__ import annotations

import json
import pathlib
import sys

output_dir = pathlib.Path(sys.argv[1])
baseline_source = sys.argv[2]
baseline_asset = sys.argv[3]
candidate_source = sys.argv[4]
candidate_run = sys.argv[5]
candidate_artifact = sys.argv[6]

baseline = json.loads((output_dir / "baseline-steady.json").read_text(encoding="utf-8"))
candidate = json.loads((output_dir / "candidate-steady.json").read_text(encoding="utf-8"))

for label, report, source in (
    ("baseline", baseline, baseline_source),
    ("candidate", candidate, candidate_source),
):
    if report.get("sourceCommit") != source:
        raise SystemExit(f"{label} source provenance mismatch")
    if report.get("resourceScope") != "compact-parent-only":
        raise SystemExit(f"{label} resource scope mismatch")
    if report.get("adapterAbsent") is not True:
        raise SystemExit(f"{label} unexpectedly observed an adapter")
    if report.get("sampleCount") != 60:
        raise SystemExit(f"{label} must contain exactly 60 samples")

baseline_parent = baseline["parent"]
candidate_parent = candidate["parent"]
summary = {
    "schemaVersion": 1,
    "diagnostic": "m6.4-rss-ab",
    "baseline": {
        "sourceCommit": baseline_source,
        "releaseAssetId": baseline_asset,
        "rssMedianKiB": baseline_parent["rssMedianKiB"],
        "rssMaxKiB": baseline_parent["rssMaxKiB"],
        "cpuMedianPercent": baseline_parent["cpuMedianPercent"],
        "cpuMaxPercent": baseline_parent["cpuMaxPercent"],
        "threadMedian": baseline_parent["threadMedian"],
        "threadMax": baseline_parent["threadMax"],
    },
    "candidate": {
        "sourceCommit": candidate_source,
        "workflowRunId": candidate_run,
        "artifactId": candidate_artifact,
        "rssMedianKiB": candidate_parent["rssMedianKiB"],
        "rssMaxKiB": candidate_parent["rssMaxKiB"],
        "cpuMedianPercent": candidate_parent["cpuMedianPercent"],
        "cpuMaxPercent": candidate_parent["cpuMaxPercent"],
        "threadMedian": candidate_parent["threadMedian"],
        "threadMax": candidate_parent["threadMax"],
    },
    "delta": {
        "rssMedianKiB": candidate_parent["rssMedianKiB"] - baseline_parent["rssMedianKiB"],
        "rssMaxKiB": candidate_parent["rssMaxKiB"] - baseline_parent["rssMaxKiB"],
    },
}
(output_dir / "summary.json").write_text(
    json.dumps(summary, sort_keys=True, indent=2) + "\n",
    encoding="utf-8",
)
PY

cat "$OUTPUT_DIR/baseline-steady.json"
cat "$OUTPUT_DIR/candidate-steady.json"
cat "$OUTPUT_DIR/summary.json"
echo "M6.4 RSS A/B evidence written to: $OUTPUT_DIR"
