# Production System Media Transport — Target Mac Procedure

This procedure completes the physical M6.3 acceptance recorded in `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.

Do not use a newer production candidate for this gate. The exact code candidate is frozen at:

- source SHA: `3932426bcf063162ee7de1378ed301c9ce664746`;
- GitHub Actions run: `31317528628` / CI `#558`;
- artifact: `ProductionMediaTransportCandidate-candidate`;
- artifact ID: `9039199985`;
- Actions artifact digest: `sha256:4e2f40fe124cc9919bbe1b17fc5759308513309c49e7fcc75bf0a9c6dac1b46d`.

Later M6.3 commits add documentation, tests and acceptance tooling only. They do not replace the physical code candidate above.

## 1. Prepare the exact candidate

From a local clone of `True-Ruslan/notch-hub`, use the M6.3 branch so the acceptance collector is available:

```bash
git fetch origin agent/m6-3-production-system-media-transport
git switch agent/m6-3-production-system-media-transport
git pull --ff-only

SOURCE_SHA="3932426bcf063162ee7de1378ed301c9ce664746"
ARTIFACT_ID="9039199985"
EXPECTED_DIGEST="sha256:4e2f40fe124cc9919bbe1b17fc5759308513309c49e7fcc75bf0a9c6dac1b46d"

ACTUAL_DIGEST="$(gh api \
  repos/True-Ruslan/notch-hub/actions/artifacts/$ARTIFACT_ID \
  --jq '.digest')"
test "$ACTUAL_DIGEST" = "$EXPECTED_DIGEST"

gh run download 31317528628 \
  --repo True-Ruslan/notch-hub \
  --name ProductionMediaTransportCandidate-candidate \
  --dir build/m6-3-candidate

rm -rf build/m6-3-candidate/extracted
mkdir -p build/m6-3-candidate/extracted build/m6-3-evidence

ditto -x -k \
  build/m6-3-candidate/ProductionMediaTransportCandidate.zip \
  build/m6-3-candidate/extracted

APP="$PWD/build/m6-3-candidate/extracted/ProductionMediaTransportCandidate.app"
CANDIDATE="$APP/Contents/MacOS/MediaTransportCandidate"
```

The Actions artifact digest is the digest reported by GitHub for artifact ID `9039199985`. It is not the SHA-256 of the nested `ProductionMediaTransportCandidate.zip` unless a separate nested-file digest is explicitly recorded.

## 2. Automated preflight

Close or stop every media source first so no system Now Playing session is active, then run:

```bash
python3 scripts/production_media_transport_acceptance.py preflight \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --output build/m6-3-evidence/preflight.json

cat build/m6-3-evidence/preflight.json
```

The collector fails closed unless all of the following are true:

- candidate bundle identifier and source/adapter/patch provenance match the frozen candidate;
- `codesign --verify --deep --strict` succeeds;
- Hardened Runtime is present;
- effective entitlements are exactly App Sandbox only;
- the real production candidate can execute the authoritative tri-state capability query;
- the output contains only privacy-safe evidence.

With no active source, `previous`, `next` and `seek` should normally be `unknown`. Never convert a no-session `unknown` into inferred support.

## 3. Automated source-cycle evidence

Start with no active Now Playing source. Then run one continuous observation:

```bash
python3 scripts/production_media_transport_acceptance.py observe \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --seconds 120 \
  --output build/m6-3-evidence/source-cycle.json
```

During those 120 seconds perform this physical sequence without stopping the command:

1. start playback in Yandex Music;
2. allow the session and artwork to settle;
3. start YouTube playback in Yandex Browser so macOS changes the authoritative Now Playing source;
4. allow the browser session to settle;
5. stop/close the active media source so the system session disappears.

Then inspect only the privacy-safe report:

```bash
cat build/m6-3-evidence/source-cycle.json
```

Expected evidence for the available target matrix:

- `observedSession = true`;
- `observedPlayingState = true`;
- Yandex Music and browser are both exercised through the same system transport, with no player-specific controller;
- `sourceSwitchCount > 0` if macOS authoritatively switched between distinct bundle identifiers during the observation;
- `observedSessionDisappearance = true` after a real session disappears;
- `cleanTeardown = true`;
- capabilities remain exact `supported | unsupported | unknown` values;
- no title, artist, album, artwork bytes, raw payload or listening history is persisted.

`observedArtworkClearOnSourceSwitch = true` is useful additional physical evidence only if the real source sequence naturally contains an artwork-bearing source followed by a distinct source without artwork. Do not manufacture this condition or install otherwise-unused software solely for the test; the regression is already deterministic-test PASS.

## 4. Actual command behavior

Use an active source that reports the corresponding capability as `supported`. Run one command at a time and confirm the **real media behavior**; process success alone is not acceptance evidence.

```bash
"$CANDIDATE" send toggle
# Confirm: playback actually pauses.

"$CANDIDATE" send toggle
# Confirm: playback actually resumes.

"$CANDIDATE" send next
# Confirm: the real next item starts, when supported.

"$CANDIDATE" send previous
# Confirm: the real previous item starts, when supported.

"$CANDIDATE" seek 42
# Confirm: playback moves to approximately 00:42, when supported.
```

Important: the M6.3 production candidate `seek` CLI accepts **seconds**. The older M6.1 probe accepted microseconds; do not reuse the old value `42000000` here.

Record the result as:

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

Unsupported is acceptable only when the authoritative capability state for that active session is `unsupported`. Do not infer unsupported from command failure.

## 5. 60-second resource evidence

Keep a real source playing steadily and avoid deliberate source switching during this measurement:

```bash
python3 scripts/production_media_transport_acceptance.py resources \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --mode steady \
  --output build/m6-3-evidence/resources-60s.json

cat build/m6-3-evidence/resources-60s.json
```

The collector uses fixed acceptance settings: 10-second warmup, 60 one-second samples, separate parent/owned-adapter CPU/RSS/thread summaries and conservative combined upper bounds. It requires exactly one owned adapter child and fails if that ownership cannot be proved.

## 6. 10-minute stability evidence

Keep the same real source active for the stability run:

```bash
python3 scripts/production_media_transport_acceptance.py resources \
  --app "$APP" \
  --source-commit "$SOURCE_SHA" \
  --mode stability \
  --output build/m6-3-evidence/resources-10min.json

cat build/m6-3-evidence/resources-10min.json
```

This records approximately ten minutes of parent + owned-adapter evidence, including start/end/first-quartile RSS and thread values, combined drift, CPU/RSS/thread summaries, natural observer teardown and orphan-process detection.

Any sustained CPU work, RSS/thread accumulation, early observer exit or owned Perl process remaining after teardown fails the gate and must be investigated before shipping composition.

## 7. Evidence to return

The minimum useful evidence set is:

```text
build/m6-3-evidence/preflight.json
build/m6-3-evidence/source-cycle.json
build/m6-3-evidence/resources-60s.json
build/m6-3-evidence/resources-10min.json
```

Plus the short manual command/permission result block from section 4.

Do not include title, artist, album, artwork, listening history, screenshots of private media libraries, or raw adapter output. The generated JSON files are intentionally limited to operational/privacy-safe evidence.

## Acceptance boundary

Passing this procedure completes only the M6.3 production transport gate. It does **not** authorize skipping review of the next shipping-composition change.

PR #16 stays Draft until the target evidence is recorded in `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md` and the M6.3 decision is explicit. Only after that may a separate slice add `NotchHubMediaCore` and the pinned adapter assets to `NotchHub.app`. Media UI remains a later slice.
