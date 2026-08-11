# Shipping Media Composition — Target Mac Procedure

This procedure completes the physical M6.4 acceptance recorded in `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`.

Use only the current frozen lazy-lifecycle candidate:

- source SHA: `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- GitHub Actions: CI `#693` / run `31472420797` — both jobs PASS;
- artifact: `NotchHub-shipping-media-candidate`;
- artifact ID: `9093958828`;
- Actions artifact digest: `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256: `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`.

Later tests/collectors/runner/documentation commits do not replace this physical candidate. Any later production/package/signing/entitlement/adapter/resource change requires a new candidate.

## 1. Prepare the repository tooling

```bash
git fetch origin agent/m6-4-shipping-media-composition
git switch agent/m6-4-shipping-media-composition
git pull --ff-only
```

Use the branch tooling, but use the exact CI candidate below rather than a local rebuild.

## 2. Download and verify the exact candidate

```bash
ARTIFACT_ID="9093958828"
EXPECTED_ARTIFACT_DIGEST="sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9"

ACTUAL_ARTIFACT_DIGEST="$(gh api \
  repos/True-Ruslan/notch-hub/actions/artifacts/$ARTIFACT_ID \
  --jq '.digest')"
test "$ACTUAL_ARTIFACT_DIGEST" = "$EXPECTED_ARTIFACT_DIGEST"

rm -rf build/m6-4-lazy-candidate
mkdir -p build/m6-4-lazy-candidate

gh run download 31472420797 \
  --repo True-Ruslan/notch-hub \
  --name NotchHub-shipping-media-candidate \
  --dir build/m6-4-lazy-candidate

shasum -a 256 build/m6-4-lazy-candidate/NotchHub.dmg
```

Required DMG SHA-256:

```text
6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd
```

The target runner verifies this hash again and fails closed on any different DMG.

## 3. Compact background acceptance

Before starting:

1. quit any existing NotchHub instance;
2. leave the pointer away from the notch for the complete run;
3. do not intentionally trigger panel expansion;
4. normal Now Playing state is irrelevant because media observation must not exist while compact;
5. avoid intentionally starting heavy benchmark/build workloads;
6. watch for any macOS permission prompt.

Run:

```bash
rm -rf build/m6-4-compact-acceptance

bash scripts/run-shipping-media-target-acceptance.sh \
  --dmg build/m6-4-lazy-candidate/NotchHub.dmg \
  --output-dir build/m6-4-compact-acceptance \
  --run-mode compact-full
```

This run takes a little over eleven minutes. The runner:

- mounts the exact DMG read-only;
- runs shipping preflight;
- launches one compact NotchHub instance;
- samples only the parent process for 60-second steady and 10-minute stability windows;
- fails immediately if an owned production media adapter appears at startup, after warmup, during any sample, or at the end;
- requests normal application termination through public `NSRunningApplication.terminate()`;
- verifies bounded parent exit;
- emits privacy-safe aggregate JSON only.

Expected files:

```text
build/m6-4-compact-acceptance/preflight.json
build/m6-4-compact-acceptance/compact-steady.json
build/m6-4-compact-acceptance/compact-stability.json
build/m6-4-compact-acceptance/summary.json
```

Required structural results:

- source commit is exactly `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- `resourceScope = compact-parent-only`;
- `adapterAbsent = true` in both resource reports and summary;
- steady sample count = `60`;
- stability sample count = `120`;
- parent normal termination succeeds.

The compact measurements are compared directly with the existing P0 target ceilings; no new runtime allowance is introduced.

## 4. Expanded active-feature acceptance

Quit any remaining NotchHub process. A normal Now Playing source such as Yandex Music may be active so the media path exercises realistic state.

Run:

```bash
rm -rf build/m6-4-expanded-acceptance

bash scripts/run-shipping-media-target-acceptance.sh \
  --dmg build/m6-4-lazy-candidate/NotchHub.dmg \
  --output-dir build/m6-4-expanded-acceptance \
  --run-mode expanded-steady
```

The app starts compact with no media runtime. The script then prints an instruction and waits for keyboard input.

At that point:

1. move the pointer over the notch;
2. wait until the panel is visibly fully expanded;
3. keep the pointer inside the expanded panel;
4. while leaving the pointer there, press Return in the terminal;
5. keep the panel expanded until the 60-second measurement finishes.

After Return, the existing active shipping collector requires exactly one owned media adapter. It gathers the normal 10-second warmup + 60 steady parent+adapter samples, starts bounded teardown observation, requests normal AppKit application termination, and requires parent exit, adapter exit, and no orphan.

Expected files:

```text
build/m6-4-expanded-acceptance/preflight.json
build/m6-4-expanded-acceptance/steady.json
build/m6-4-expanded-acceptance/teardown.json
build/m6-4-expanded-acceptance/summary.json
```

Expanded resource values are active feature-cost evidence. They are not substituted for the compact P0 idle budget.

## 5. Human permission observation

Across both runs record:

```text
Accessibility — NONE/SHOWN
Input Monitoring — NONE/SHOWN
Automation — NONE/SHOWN
Screen Recording — NONE/SHOWN
```

Any `SHOWN` result blocks acceptance. Do not grant a new permission merely to make the test pass.

## 6. Evidence to return

Return/upload:

- all four JSON files from `build/m6-4-compact-acceptance/`;
- all four JSON files from `build/m6-4-expanded-acceptance/`;
- the four-line permission block.

Do not include media title/artist/album/artwork/listening history, screenshots of private media libraries, raw MediaRemote payloads, or process-table dumps. PID values are internal only and are absent from final evidence.

## Acceptance boundary

Passing these two runs completes only the M6.4 shipping-composition physical gate. PR #17 remains Draft until current-candidate evidence is recorded in the ledger and the decision becomes explicitly `ACCEPTED`.

Media UI, progress rendering, gesture/haptic/seek interaction, and additional-player compatibility remain later slices.
