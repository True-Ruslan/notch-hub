# Roadmap

Primary target: macOS 26.6 / Mac16,8. Published Personal Release: `v0.1.0`.

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**: Swift 6 native shell, notch geometry, AppKit/SwiftUI ownership, Sandbox/Hardened Runtime, strict CI/security/release policy.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable ad-hoc-signed `v0.1.0`; Developer ID/notarization remains optional/deferred.
- **P0 Performance Foundation — ACCEPTED / MERGED**: immutable baseline, same-session resource methodology and deterministic artifact-size policy.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**: 120 ms cancellable hover, deterministic activation/retention, one expansion haptic, single transition authority, Reduce Motion, explicit monitor ownership. Active-display/fullscreen/Spaces/notchless/click-pin hardening remains deferred.

## M6 — Universal Media / System Now Playing

Product contract: player-agnostic macOS Now Playing source, truthful capabilities/metadata, event-driven lifecycle, zero persistent adapter while compact, local-only gestures, no sensitive input permissions or synthetic media keys.

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — local gestures, haptics, interactive notch and seek

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICAL RETEST PENDING / NOT MERGED**.

Merged prerequisites on `main` include one-shot lifecycle ownership, deterministic gesture coordinator, local AppKit scroll seam, bounded compact previous/next dispatcher, interactive transition authority and vertical visual tracking.

Draft PR #33 contains the consolidated user-visible slice:

- local `MediaGestureSession` and bounded horizontal visual model;
- one-arm-haptic previous/next semantics;
- follow-finger compact/expanded interactive panel motion;
- public `NSWorkspace` source-app icon badge with bounded cache;
- capability-gated draggable seek;
- source/track identity-locked seek cancellation;
- hover/gesture arbitration that keeps media wings interactive without broadening hover activation;
- physical-axis normalization: RIGHT previous, LEFT next, DOWN expand, UP collapse;
- bounded event-driven media/Home and horizontal-release visual continuity;
- dedicated physical-acceptance repair size budget over immutable P0.

The first candidate `d008f698b323963f084eedce601620ee957ef442` was rejected by target testing despite CI #872 success. Repair head `6403dae0e33281f6dcd5bcbd79ec5147b6580c0a` passed CI #883; documentation sync and one new exact candidate precede the required retest.

Acceptance ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`.

No P1 work or merge is allowed before this physical acceptance closes.

## P1 — whole-app performance/resource review

Status: **AFTER M6.6 ACCEPTANCE**.

Planned:

- remeasure the real functional app on the target Mac;
- CPU/RSS/threads plus wakeups/energy/compositor continuity;
- compare current global `.mouseMoved` fallback with reliable local tracking and adopt local-only only if correctness/resources are equal-or-better;
- characterize repeated-run variance before any new absolute memory gate.

## Product modules after media/performance foundation

- **M2 Shelf** — sandbox-compatible file references and security-scoped access; removing a reference never deletes source data.
- **M3 Snippets** — sandbox-local store, groups/search/copy; direct paste only after separate Accessibility decision.
- **M4 Calendar** — EventKit adapter, explicit permission/denial states.
- **M5 Translator** — Apple Translation where available; no direct app-network translation without separate review.
- **M7 Product shell** — settings, narrow shortcuts, supported launch-at-login, module ordering/enable-disable.
- **M8 Trusted distribution — optional** — Developer ID/notarization only if Apple Developer Program membership becomes worthwhile; never replace an existing published tag.

## Current priority

1. Finish docs-sync exact candidate CI for PR #33.
2. Run focused target-Mac M6.6 retest, including compact/expanded directions, hover parity, seek source-change cancellation, source icon, permissions and process teardown.
3. If feel requires it, perform the single allowed visual travel/damping tuning pass with deterministic tests and a new exact candidate.
4. Only after full physical PASS: record acceptance, make PR #33 ready, merge and verify post-merge `main` CI.
5. Then start P1.
