# Shipping Media Composition — Target Mac Procedure

This procedure completes the physical M6.4 acceptance recorded in `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`.

Use only the frozen shipping candidate:

- source SHA: `c19ce13c5321fce72464ddf0a5d9b1467f770db0`;
- GitHub Actions: CI `#675` / run `31408757149`;
- artifact: `NotchHub-shipping-media-candidate`;
- artifact ID: `9070996306`;
- Actions artifact digest: `sha256:c3b279153b8abf75ab77fa2f478888ae1fe9bad6bfdbf64665567bf713b8035d`;
- contained DMG SHA-256: `ccf8a503515d382c206c6211606ca6401ba33114863a30721e134c1a45af04b9`.

Later acceptance-tooling/tests/documentation commits do not replace this physical shipping candidate. Any later shipping production/package/signing/security/entitlement/adapter/resource change requires a new candidate.

## 1. Prepare the repository tooling

From a local clone of `True-Ruslan/notch-hub`:

```bash
git fetch origin agent/m6-4-shipping-media-composition
git switch agent/m6-4-shipping-media-composition
git pull --ff-only
```

The branch contains the target runner and collector; the application itself must come from CI #675 rather than a local rebuild.

## 2. Download the exact CI candidate

```bash
ARTIFACT_ID="9070996306"
EXPECTED_ARTIFACT_DIGEST="sha256:c3b279153b8abf75ab77fa2f478888ae1fe9bad6bfdbf64665567bf713b8035d"

ACTUAL_ARTIFACT_DIGEST="$(gh api \
  repos/True-Ruslan/notch-hub/actions/artifacts/$ARTIFACT_ID \
  --jq '.digest')"
test "$ACTUAL_ARTIFACT_DIGEST" = "$EXPECTED_ARTIFACT_DIGEST"

rm -rf build/m6-4-candidate build/m6-4-target-acceptance
mkdir -p build/m6-4-candidate

gh run download 31408757149 \
  --repo True-Ruslan/notch-hub \
  --name NotchHub-shipping-media-candidate \
  --dir build/m6-4-candidate

shasum -a 256 build/m6-4-candidate/NotchHub.dmg
```

Required contained DMG SHA-256:

```text
ccf8a503515d382c206c6211606ca6401ba33114863a30721e134c1a45af04b9
```

The target runner independently enforces this hash and fails closed on any different DMG.

## 3. Prepare realistic runtime conditions

Before starting:

1. quit any existing NotchHub process;
2. start Yandex Music playback and leave one normal Now Playing source active during the run;
3. keep the Mac in its normal power mode and avoid intentionally starting heavy benchmark/build workloads;
4. watch for any macOS permission prompt during the complete run.

The M6.3 transport behavior itself is already accepted. M6.4 is measuring the real shipping composition, owned process lifecycle, whole-app resource impact, and permission posture.

## 4. Run the complete automated target acceptance

Run one command:

```bash
bash scripts/run-shipping-media-target-acceptance.sh \
  --dmg build/m6-4-candidate/NotchHub.dmg \
  --output-dir build/m6-4-target-acceptance
```

The runner intentionally:

- verifies the exact frozen DMG SHA before mounting;
- mounts the DMG read-only;
- runs the shipping preflight against the mounted app;
- launches exactly one `NotchHub` instance;
- discovers exactly one owned production adapter child;
- collects 60 steady samples after the fixed warmup;
- collects 120 stability samples at five-second intervals after the fixed warmup;
- starts bounded teardown observation;
- requests normal application termination with public `NSRunningApplication.terminate()`;
- verifies app exit, adapter exit, and no orphan adapter;
- writes privacy-safe JSON evidence only.

It does not use AppleScript, System Events, `kill -9`, or `pkill` as the acceptance termination path.

The complete run takes a little over eleven minutes because both the 60-second and 10-minute measurements are intentional acceptance gates.

## 5. Required output

A successful run creates:

```text
build/m6-4-target-acceptance/preflight.json
build/m6-4-target-acceptance/steady.json
build/m6-4-target-acceptance/stability.json
build/m6-4-target-acceptance/teardown.json
build/m6-4-target-acceptance/summary.json
```

Required structural results:

- `preflight.json` reports source `c19ce13c...`, exact adapter/patch provenance, verified resources/signatures/Hardened Runtime/sandbox/system libraries and no dev tools;
- `steady.json` has `mode = steady` and `sampleCount = 60`;
- `stability.json` has `mode = stability` and `sampleCount = 120`;
- `teardown.json` has `parentExited = true`, `adapterExited = true`, `orphanProcessDetected = false`;
- `summary.json` repeats the exact source and successful structural gate results.

For resource acceptance, inspect parent, adapter and conservative combined summaries. The expected qualitative gate is no sustained CPU work and no RSS/thread accumulation over the stability run. Do not invent a new hosted-runner-derived numeric ceiling.

## 6. Human permission observation

Record only this block for the complete run:

```text
Accessibility — NONE/SHOWN
Input Monitoring — NONE/SHOWN
Automation — NONE/SHOWN
Screen Recording — NONE/SHOWN
```

A prompt marked `SHOWN` blocks M6.4 acceptance and requires investigation; do not grant a new permission merely to make the test pass.

## 7. Evidence to return

Return/upload the five JSON files from section 5 plus the four-line permission block from section 6.

Do not include media title, artist, album, artwork, listening history, screenshots of private media libraries, raw MediaRemote payloads, or process-table dumps. PID values are used internally by the collector but are intentionally absent from final evidence.

## Acceptance boundary

Passing this procedure completes only the M6.4 shipping-composition physical gate. PR #17 remains Draft until current-candidate evidence is recorded in the ledger and the final decision becomes `ACCEPTED`.

Compact/expanded Media UI, progress rendering, gesture/haptic/seek interaction, and additional-player compatibility remain later slices.
