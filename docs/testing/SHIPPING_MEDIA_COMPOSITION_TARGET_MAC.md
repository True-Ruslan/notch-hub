# Shipping Media Composition — Target Mac Procedure

Status: **COMPLETED — M6.4 PHYSICAL ACCEPTANCE RECORDED**

This procedure documents the physical M6.4 acceptance recorded in `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md` and the additional same-session comparators used to resolve the historical absolute-RSS discrepancy.

Use only the accepted frozen lazy-lifecycle candidate:

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

The runner:

- mounts the exact DMG read-only;
- runs shipping preflight;
- launches one compact NotchHub instance;
- records `60` parent-only steady samples at `1 s` cadence after `10 s` warmup;
- records `120` parent-only stability samples at `5 s` cadence after `10 s` warmup (nominal approximately ten-minute stability evidence);
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

- source commit exactly `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- `resourceScope = compact-parent-only`;
- `adapterAbsent = true` in both resource reports and summary;
- steady sample count `60`;
- stability sample count `120`;
- parent normal termination succeeds.

Runtime interpretation follows `PERFORMANCE.md`: the immutable P0 historical absolute `ps rss` value is not a standalone cross-session gate. Compact steady memory is evaluated with exact same-session immutable-baseline A/B when historical absolute values disagree, while the 10-minute RSS/thread growth gates remain direct acceptance criteria.

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

The app starts compact with no media runtime. The script prints an instruction and waits for keyboard input.

At that point:

1. move the pointer over the notch;
2. wait until the panel is visibly fully expanded;
3. keep the pointer inside the expanded panel;
4. while leaving the pointer there, press Return in the terminal;
5. keep the panel expanded until the steady measurement finishes.

After Return, the active shipping collector requires exactly one owned media adapter. It gathers the normal `10 s` warmup + `60` steady samples at `1 s` cadence for parent and adapter, starts bounded teardown observation, requests normal AppKit application termination, and requires parent exit, adapter exit, and no orphan.

Expected files:

```text
build/m6-4-expanded-acceptance/preflight.json
build/m6-4-expanded-acceptance/steady.json
build/m6-4-expanded-acceptance/teardown.json
build/m6-4-expanded-acceptance/summary.json
```

Expanded resource values are active feature-cost evidence. They are not substituted for compact steady comparison.

## 5. Human permission observation

Across both runs record:

```text
Accessibility — NONE/SHOWN
Input Monitoring — NONE/SHOWN
Automation — NONE/SHOWN
Screen Recording — NONE/SHOWN
```

Any `SHOWN` result blocks acceptance. Do not grant a new permission merely to make the test pass.

Accepted M6.4 observation: all four categories were `NONE`.

## 6. Historical shell-only diagnostic

The first compact run exceeded the old single-session absolute P0 RSS ceiling despite zero adapter. Before changing M6.4 production code, exact final M6.3 shell-only shipping was measured with the same parent-only collector:

```bash
bash scripts/run-shell-only-target-diagnostic.sh \
  --dmg build/m6-3-shell-only-candidate/NotchHub.dmg \
  --output-dir build/m6-3-shell-only-diagnostic
```

Exact comparator:

- source `30de94c0cb6ea17dc21bd366404937db2bc73783`;
- CI #594 / run `31389611697`;
- artifact ID `9063213178`;
- DMG SHA-256 `b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7`.

Result: steady RSS median/max `58,656/62,624 KiB`, stability `56,384/60,400 KiB`, adapter absent. This disproved M6.4 static media linkage as the source of the historical absolute-RSS discrepancy.

## 7. Immutable baseline vs M1 same-session diagnostic

To distinguish a code regression from metric/session portability, exact immutable `v0.1.0` and accepted M1 #319 were measured back-to-back:

```bash
bash scripts/run-shell-rss-bisect.sh \
  --baseline-dmg build/p0-baseline-release/NotchHub.dmg \
  --m1-dmg build/m1-319-candidate/NotchHub.dmg \
  --output-dir build/shell-rss-bisect
```

Result:

- immutable `v0.1.0` RSS median/max `60,144/63,376 KiB`;
- M1 #319 RSS median/max `59,552/69,680 KiB`;
- median delta `-592 KiB`.

A persistent P0→M1 memory regression was disproven. The exact baseline binary itself now reproduces the current ~60 MiB RSS class.

## 8. Final immutable baseline vs frozen M6.4 A/B

The final steady resource decision uses the exact immutable P0 release and frozen M6.4 candidate in one session through one literal shared collector path:

```bash
rm -rf build/m6-4-rss-ab

bash scripts/run-m6-4-rss-ab.sh \
  --baseline-dmg build/p0-baseline-release/NotchHub.dmg \
  --candidate-dmg build/m6-4-lazy-candidate/NotchHub.dmg \
  --output-dir build/m6-4-rss-ab
```

Accepted result:

- baseline CPU median/max `0.0/6.7%`, RSS median/max `61,504/67,104 KiB`, threads `3/4`;
- frozen M6.4 CPU median/max `0.0/0.0%`, RSS median/max `62,256/65,232 KiB`, threads `3/4`;
- candidate RSS delta `+752 KiB` median and `-1,872 KiB` max.

The exact baseline's own two same-day steady medians differed by `1,360 KiB`, larger than the M6.4 median delta. M6.4 therefore shows no material directionally consistent steady compact-memory regression. Combined with compact stability drift `+2,672 KiB` inside the retained `+8,192 KiB` growth gate and threads `3 -> 3`, `NH-MEDIA-SHIP-008/009` pass.

No value in `performance/baseline-v0.1.0.json` was rewritten and no numeric production runtime budget was raised to get this result.

## 9. Evidence privacy

Final evidence may contain only aggregate resource/provenance/security/lifecycle information. Do not include media title/artist/album/artwork/listening history, screenshots of private media libraries, raw MediaRemote payloads, or process-table dumps. PID values are internal only and absent from final evidence.

## Acceptance boundary

All M6.4 physical gates are complete and recorded as accepted in `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`.

PR #17 may proceed through final exact-head CI/change review and squash merge. Media UI, progress rendering, gesture/haptic/seek interaction, and additional-player compatibility remain later slices.
