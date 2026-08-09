# Production System Media Transport — Target Mac Procedure

This procedure completes the physical M6.3 acceptance recorded in `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.

The previous #558 candidate is superseded after the target-Mac 10-minute run exposed an unbounded production process-teardown defect. Use only the current exact candidate:

- source SHA: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- GitHub Actions run: `31339015100` / CI `#576`;
- artifact: `ProductionMediaTransportCandidate-candidate`;
- artifact ID: `9045247126`;
- artifact size: `199242` bytes;
- Actions artifact digest: `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`.

Later documentation-only acceptance commits do not replace this physical code candidate. Any later production transport/candidate packaging/signing/security-policy/adapter/patch/entitlement change requires a new exact candidate.

## 1. Prepare the exact candidate

From a local clone of `True-Ruslan/notch-hub`:

```bash
git fetch origin agent/m6-3-production-system-media-transport
git switch agent/m6-3-production-system-media-transport
git pull --ff-only

SOURCE_SHA="c63f39c40b90d647e48271b9dc1d5ffd6e612c0b"
ARTIFACT_ID="9045247126"
EXPECTED_DIGEST="sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804"

ACTUAL_DIGEST="$(gh api \
  repos/True-Ruslan/notch-hub/actions/artifacts/$ARTIFACT_ID \
  --jq '.digest')"
test "$ACTUAL_DIGEST" = "$EXPECTED_DIGEST"

# Remove only the previous local candidate download. This makes the command
# idempotent and avoids `gh run download ... file exists`.
rm -rf build/m6-3-candidate
mkdir -p build/m6-3-candidate build/m6-3-evidence

gh run download 31339015100 \
  --repo True-Ruslan/notch-hub \
  --name ProductionMediaTransportCandidate-candidate \
  --dir build/m6-3-candidate

mkdir -p build/m6-3-candidate/extracted
ditto -x -k \
  build/m6-3-candidate/ProductionMediaTransportCandidate.zip \
  build/m6-3-candidate/extracted

APP="$PWD/build/m6-3-candidate/extracted/ProductionMediaTransportCandidate.app"
CANDIDATE="$APP/Contents/MacOS/MediaTransportCandidate"
```

The Actions artifact digest is GitHub's digest for artifact ID `9045247126`; it is not necessarily the SHA-256 of the nested `ProductionMediaTransportCandidate.zip`.

## 2. Automated preflight — start with no media session

Stop/close Yandex Music, browser playback and any other active system Now Playing source first. Then run:

```bash
python3 scripts/production_media_transport_acceptance.py preflight \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --output build/m6-3-evidence/preflight.json

cat build/m6-3-evidence/preflight.json
```

Required:

- source/adapter/patch provenance matches the current exact candidate;
- strict code-sign verification succeeds;
- Hardened Runtime is present;
- effective entitlements are exactly App Sandbox only;
- platform is `Mac16,8` / macOS 26.6;
- with no active source, previous/next/seek should normally be `unknown/unknown/unknown` and must never be inferred as supported.

## 3. Automated source-cycle evidence

Begin with no active Now Playing source and run:

```bash
python3 scripts/production_media_transport_acceptance.py observe \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --seconds 120 \
  --output build/m6-3-evidence/source-cycle.json
```

During the 120 seconds, without stopping the command:

1. start Yandex Music playback and leave it active for several seconds;
2. start YouTube playback in Yandex Browser and verify that macOS actually changes the system Now Playing source;
3. leave the browser source active for several seconds;
4. stop/close the active media source so the system session disappears.

Then:

```bash
cat build/m6-3-evidence/source-cycle.json
```

Required evidence:

- `observedSession = true`;
- `observedPlayingState = true`;
- `sourceSwitchCount > 0` for the Yandex Music -> browser switch;
- `observedSessionDisappearance = true`;
- `cleanTeardown = true`;
- exact tri-state capabilities only;
- no private metadata/raw payload retained.

If `sourceSwitchCount` remains `0`, do not guess that switching worked: repeat only this source-cycle after ensuring macOS really hands Now Playing ownership to Yandex Browser.

`observedArtworkClearOnSourceSwitch = true` is optional physical evidence only when the real source sequence naturally switches from an artwork-bearing source to a distinct source without artwork. Do not manufacture this condition.

## 4. Actual command behavior

With Yandex Music or another active source reporting the corresponding capability as `supported`, run each command separately and confirm the real player behavior:

```bash
"$CANDIDATE" send toggle
# playback actually pauses

"$CANDIDATE" send toggle
# playback actually resumes

"$CANDIDATE" send next
# next item actually starts, when supported

"$CANDIDATE" send previous
# previous item actually starts, when supported

"$CANDIDATE" seek 42
# playback actually moves to approximately 00:42, when supported
```

The M6.3 candidate seek argument is **seconds**.

Record:

```text
Yandex Music / active source:
toggle pause — PASS/FAIL
toggle resume — PASS/FAIL
next — PASS/FAIL/UNSUPPORTED
previous — PASS/FAIL/UNSUPPORTED
seek 42s — PASS/FAIL/UNSUPPORTED

Permission prompts during the complete cycle:
Accessibility — NONE/SHOWN
Input Monitoring — NONE/SHOWN
Automation — NONE/SHOWN
Screen Recording — NONE/SHOWN
```

`UNSUPPORTED` is acceptable only if the authoritative capability state is `unsupported`.

## 5. 60-second resource evidence

Keep one real source playing steadily:

```bash
python3 scripts/production_media_transport_acceptance.py resources \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --mode steady \
  --output build/m6-3-evidence/resources-60s.json

cat build/m6-3-evidence/resources-60s.json
```

The collector records 60 one-second samples after the fixed warmup, separately measures parent and exactly one owned adapter child, reports conservative combined CPU/RSS/thread upper bounds, and fails closed on ambiguous ownership or teardown.

## 6. 10-minute stability evidence

Keep the same source active:

```bash
python3 scripts/production_media_transport_acceptance.py resources \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --mode stability \
  --output build/m6-3-evidence/resources-10min.json

cat build/m6-3-evidence/resources-10min.json
```

This is the regression gate for the target-discovered defect. The current candidate uses bounded process teardown: at most 1 second graceful wait, then owned-child `SIGKILL` if needed, then at most 1 second forced wait. The outer collector watchdog remains intentionally larger and should no longer terminate a correctly functioning candidate.

Required:

- approximately 10 minutes of parent + adapter metrics are produced;
- no sustained CPU work or RSS/thread accumulation;
- `observerReport.cleanTeardown = true`;
- `orphanProcessDetected = false`;
- the command returns normally and creates `resources-10min.json`.

A timeout, missing JSON, unconfirmed teardown or owned adapter process after completion is a FAIL requiring investigation.

## 7. Evidence to return

Return these four current-candidate files:

```text
build/m6-3-evidence/preflight.json
build/m6-3-evidence/source-cycle.json
build/m6-3-evidence/resources-60s.json
build/m6-3-evidence/resources-10min.json
```

Plus the short command/permission block from section 4.

The old #558 JSON files remain useful diagnostic evidence and are recorded in the ledger, but they are not mixed into final acceptance because production process lifecycle code changed after the target defect was found.

Do not include title, artist, album, artwork, listening history, screenshots of private media libraries or raw adapter output.

## Acceptance boundary

Passing this procedure completes only M6.3. PR #16 stays Draft until current-candidate target evidence is recorded and the decision is explicit. Shipping composition (`NotchHubMediaCore` + pinned adapter assets inside `NotchHub.app`) remains a separate reviewed slice; Media UI remains later.
