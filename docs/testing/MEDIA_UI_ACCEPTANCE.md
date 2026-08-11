# M6.5 Media-first UI Acceptance

Status: **IMPLEMENTED / AUTOMATED-TESTED / TARGET-MAC ACCEPTANCE PENDING / NOT ACCEPTED / NOT MERGED / NOT RELEASED**
Date: 2026-08-11
PR: #19 — `M6.5 Media-first UI`
Primary target: `Mac16,8` / macOS 26.6
Design: `docs/superpowers/specs/2026-08-11-media-first-ui-design.md`
Implementation plan: `docs/superpowers/plans/2026-08-11-media-first-ui.md`

## Scope

M6.5 adds the first shipping Universal Media presentation on top of the accepted M6.1–M6.4 transport/composition foundation without weakening the accepted presentation-scoped media lifecycle.

Implemented product behavior:

- cold ordinary compact remains the exact physical-notch frame and starts no media runtime;
- settled expansion creates/starts the existing `ShippingMediaRuntime`;
- authoritative media state is projected into a presentation-only App-owned model;
- expanded active media renders artwork/metadata/source, capability-driven previous/play-pause/next controls and event-driven static progress when timing is trustworthy;
- missing/blank metadata is omitted rather than fabricated;
- unsupported/unknown previous/next capabilities remain disabled;
- session disappearance/unavailable while expanded replaces Media with the existing Home/foundation presentation without collapsing the panel;
- normal collapse detaches the presentation callback before runtime teardown, preserving the last authoritative media context while the adapter is absent;
- retained-media compact uses 36 pt symmetric visible wings around the unchanged physical notch, with artwork left and playback status right;
- the physical notch center remains clear/black;
- a later expanded runtime may replace retained context regardless of its newly restarted local sequence numbering; `MediaSessionController` remains the sole freshness/order authority;
- gestures, haptics, draggable seek, animated progress and live compact observation remain deferred.

## Architecture/security invariants retained

- `NotchHubCore` does not import or depend on `NotchHubMediaCore`;
- `NotchHubApp` remains the composition root;
- `NotchPanelTransitionCoordinator` remains the sole panel geometry/transition authority;
- App media code never calls `NSPanel.setFrame` directly;
- compact media wings are a generic layout input consumed by the existing transition/pointer path;
- App Sandbox remains the only application entitlement;
- Hardened Runtime remains enabled;
- production process authority remains the previously accepted fixed `/usr/bin/perl` media boundary;
- no Accessibility, Input Monitoring, Automation, Screen Recording, synthetic media key, AppleScript, direct network, telemetry or player-specific fallback was added;
- no repeating `Timer`, timer publisher, `DispatchSourceTimer`, display link, sleep loop, media polling loop or global scroll monitor was added;
- media title/artist/album/artwork/listening history is not persisted or emitted into ordinary production logs.

## TDD evidence

### Core content composition seam

RED:

- source `c0c54793417981f3b4ed6e4e0965136c653e742b`;
- CI #736 / run `31535386429`;
- production build passed;
- tests failed on the intentionally missing generic `NotchHostingViewFactory.make(rootView:)` / content injection contract.

GREEN:

- source `a33246d2e509530bad099c6fa30b6ae7877c19c8`;
- CI #738 / run `31535524022`;
- warnings-as-errors build and full Swift suite passed.

### Media presentation projection

RED:

- source `9c3c43b5e2b43899d78ab1d856fb47c35ce5128b`;
- CI #740 / run `31535765930`;
- production build passed;
- tests failed because `ShippingMediaPresentationModel` did not exist.

GREEN:

- source `ca4f7ffdfe7ddc30bf621b49baad591de1a6075e`;
- CI #741 / run `31535972395`;
- warnings-as-errors build and full Swift suite passed.

### Runtime presentation lifecycle / typed click commands

RED:

- source `258c8882f98c90c315bfeb5ecaac2fae81a22fde`;
- CI #742 / run `31536134293`;
- production build passed;
- new runtime presentation-policy tests failed on the intentionally absent wiring.

GREEN:

- source `931efef1496e3a9ad6e3fbd184fecc2829ff9124`;
- CI #743 / run `31536442620`;
- warnings-as-errors build and full Swift suite passed.

### App media UI composition

RED:

- CI #745 / run `31536599074`;
- production build passed;
- App/UI source-contract expectations failed before production UI existed.

During this RED phase, inspection found that putting artwork/status inside the accepted exact hardware-notch width would make it physically occluded by the camera housing. Tests/spec were corrected before GREEN to require 36 pt symmetric media wings while preserving exact-notch ordinary compact.

GREEN code reached full Swift build/test success before packaging-policy review. A source-format failure in CI #756 was isolated to one trailing comma in a new source-policy test and fixed without changing production behavior.

## Artifact-size investigation

The first complete Media UI candidate passed tests/security/signing but correctly failed the old M6.4 transport-only size envelope:

- executable `412,992 B`;
- app `715,198 B`;
- DMG `465,177 B`.

Review found avoidable duplication of the existing Foundation/Home SwiftUI presentation inside the new media root. M6.5 was refactored to reuse the existing `NotchRootView` rather than shipping a duplicate implementation.

Optimized evidence from source `3db9d05619b38198c00b57b3cdd043af0618f714`, CI #759 / run `31537964825`:

- executable `397,408 B` (`-15,584 B` versus the first complete candidate);
- app `699,614 B` (`-15,584 B`);
- DMG `461,748 B` (`-3,429 B`);
- shipping artifact ID `9119647587`.

The remaining growth is real shipping Media UI cost. The immutable P0 baseline and historical M6.4 budget were not rewritten. A separate cumulative M6.5 feature envelope was developed RED -> GREEN:

RED:

- source `5ab37d076096f64ad1698503d7cd93871c412e7d`;
- CI #760 / run `31538512824`;
- macOS 26 job passed;
- performance-policy tests failed exactly because the M6.5 budget file did not yet exist and CI still referenced the M6.4 envelope.

GREEN:

- M6.5 budget: `performance/m6-5-media-first-ui-size-budget.json`;
- immutable baseline: `performance/baseline-v0.1.0.json` unchanged;
- historical M6.4 budget: `performance/m6-4-shipping-media-size-budget.json` unchanged;
- executable cumulative allowance `135,168 B`, adjusted absolute ceiling `401,408 B`;
- app cumulative allowance `430,080 B`, adjusted absolute ceiling `700,416 B`;
- DMG cumulative allowance `376,832 B`, adjusted absolute ceiling `466,944 B`;
- the DMG allowance includes one extra 4 KiB block beyond the minimum required round-up because prior accepted evidence established small UDZO container-level byte variance while executable/app payloads remain reproducible.

No runtime CPU/RSS/thread budget was widened.

## Current automated candidate

Exact source:

- `e9be9b361ae14c728bfefa7af53aeefe20f9145c`.

CI:

- #762 / run `31538838620` — **both jobs PASS**;
- `macOS 26 compatibility` — PASS;
- `Build, test and package` — PASS.

Shipping artifact:

- name `NotchHub-shipping-media-candidate`;
- artifact ID `9120005278`;
- Actions digest `sha256:59c060f434818d9bde8e5244cef8493fec586d01a3148de3731635f58f82eb59`;
- contained `NotchHub.dmg` SHA-256 `47921a0a064a5de8ba5dbe9f24c260082ad774b5929c98bcbd4847b14d60d364`.

Exact deterministic sizes:

- executable `397,408 B`;
- app physical payload `699,614 B`;
- DMG `461,763 B`.

Automated evidence on this source includes:

- 194 Swift tests with coverage instrumentation — PASS;
- release-policy tests — PASS;
- performance-policy and feature-size-policy tests — PASS;
- media bridge/probe policy tests — PASS;
- runtime performance source audit — PASS;
- strict Swift formatting / plist / shell validation — PASS;
- full `scripts/security-audit.sh` — PASS;
- warnings-as-errors builds — PASS;
- App Sandbox effective entitlement exactly `com.apple.security.app-sandbox=true` — PASS;
- Hardened Runtime / ad-hoc signature — PASS;
- nested media framework signature — PASS;
- system-library-only application executable boundary — PASS;
- shipping media resource/provenance preflight — PASS;
- M6.5 feature-size envelope — PASS;
- shared-runner performance harness compatibility/schema smoke — PASS.

Shared-runner CPU/RSS/thread values remain compatibility evidence only and are not target-Mac performance acceptance.

## Acceptance ledger

- `NH-MEDIA-UI-001` — cold exact-notch compact / no retained media / zero adapter: deterministic lifecycle+geometry coverage **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-002` — expanded authoritative session -> Media-first UI: deterministic composition/state coverage **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-003` — playing/paused presentation mapping: deterministic **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-004` — partial metadata / invalid artwork fallback without fabrication: deterministic **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-005` — capability-driven previous/next controls: deterministic **PASS**, physical command confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-006` — trustworthy event-driven static progress / no periodic worker: deterministic + source policy **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-007` — media disappearance while expanded -> Home without collapse and future compact extension reset: deterministic architecture/source contract **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-008` — retained compact context, 36 pt wings, adapter absent after settled collapse: deterministic geometry/lifecycle **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-009` — fresh expanded runtime rebases retained context; no cross-runtime raw sequence comparison: deterministic **PASS**, physical confirmation **PENDING as part of 011**.
- `NH-MEDIA-UI-010` — typed command/transition/security boundary and no new authority/polling surface: automated policy/security **PASS**.
- `NH-MEDIA-UI-011` — exact target-Mac visual/functional acceptance on `Mac16,8` / macOS 26.6 with Yandex Music + Yandex Browser: **PENDING TARGET MAC**.

Because `NH-MEDIA-UI-011` is pending, M6.5 is **not accepted** and PR #19 must remain draft/not merged.

## Target-Mac procedure — `NH-MEDIA-UI-011`

Use the exact final PR artifact once the documentation-only exact-head CI is green. Do not substitute a local rebuild or older candidate.

### A. Cold compact / zero-adapter gate

1. Quit any installed NotchHub instance.
2. Install/run the exact CI DMG candidate.
3. Before expanding, confirm the panel remains the ordinary exact physical-notch compact presentation.
4. Confirm there is no owned media adapter process while compact.

Expected: ordinary compact indicator only; physical notch width remains exact; no adapter exists.

### B. Yandex Music expanded Media-first

1. Start playback in Yandex Music.
2. Deliberately hover to expand NotchHub.
3. After the panel settles expanded, verify Media replaces Home when the authoritative session arrives.
4. Verify artwork/title/artist/album only when actually supplied; missing fields must not create empty/fake rows.
5. Verify the source label is Yandex Music (or the authoritative source label exposed by the transport).
6. Verify play/pause icon/state follows authoritative playing/paused updates.
7. Exercise play/pause.
8. Exercise previous/next only where the UI reports the capability as enabled.
9. If trustworthy timing is present, verify a static progress indicator appears. It must not be draggable in M6.5.

Expected: actual media commands work through the accepted transport; no fabricated capability or metadata appears.

### C. Media disappearance while expanded

1. While NotchHub remains expanded, terminate/clear the active system Now Playing session.
2. Observe the panel without moving the pointer away.

Expected: expanded panel stays expanded; content becomes the existing Home/foundation surface; it does not collapse because media disappeared.

### D. Retained compact wings / zero adapter

1. Reactivate a Yandex Music session and ensure Media-first expanded content is visible.
2. Move pointer away and allow normal collapse.
3. Verify compact now has visible symmetric media wings around the physical notch: artwork on the left, playback status on the right, camera/notch center visually clear.
4. Confirm the media adapter process is absent after compact settlement.

Expected: retained visual context survives normal runtime teardown; compact background work remains zero-adapter.

### E. Fresh re-expansion

1. Change track/state while compact using the player itself.
2. Re-expand NotchHub.
3. Verify the newly started runtime replaces retained compact context with fresh authoritative state when events arrive.

Expected: stale retained context never overrides fresh runtime state; raw sequence values from different runtime lifetimes are not compared by the presentation model.

### F. Yandex Browser

Repeat B–E with media exposed through Yandex Browser / Chromium system Now Playing. Respect actual capabilities; unsupported capability is not a failure.

### G. Permission and teardown gate

Throughout the procedure verify there are no prompts for:

- Accessibility;
- Input Monitoring;
- Automation / Apple Events;
- Screen Recording.

Quit NotchHub normally and confirm no media adapter remains orphaned.

## Exit decision

Only after `NH-MEDIA-UI-011` passes on the exact final artifact may M6.5 be marked **ACCEPTED**, PR #19 be subjected to final exact-head review/CI and squash-merged, and the roadmap advance to the separate gesture/haptic/seek slice.
