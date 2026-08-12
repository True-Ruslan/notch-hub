# Roadmap

Primary target: macOS 26.6 / Mac16,8. Published Personal Release: `v0.1.0`.

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**: Swift 6 native shell, notch geometry, AppKit/SwiftUI ownership, Sandbox/Hardened Runtime, strict CI/security/release policy.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable ad-hoc-signed `v0.1.0`; Developer ID/notarization remains optional/deferred.
- **P0 Performance Foundation — ACCEPTED / MERGED**: immutable baseline, same-session resource methodology and deterministic artifact-size policy.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**: deterministic hover/transition authority, Reduce Motion and explicit monitor ownership. Active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains deferred.

## M6 — Universal Media / System Now Playing

Product contract: player-agnostic macOS Now Playing source, truthful capabilities/metadata, event-driven lifecycle, zero persistent adapter while compact, local-only gestures, no sensitive input permissions or synthetic media keys.

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — gestures, haptics, interactive notch, seek and Hover Peek

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICAL ACCEPTANCE PENDING / NOT MERGED / NOT RELEASED**.

Merged prerequisites on `main` include one-shot lifecycle ownership, deterministic gesture coordinator, local AppKit scroll seam, bounded compact previous/next dispatcher, interactive transition authority and vertical visual tracking.

Draft PR #33 contains the consolidated user-visible slice:

- stable `compact`, `peek`, `expanded` presentations under one panel transition authority;
- 120 ms hover dwell to media-only Peek and 140 ms Peek exit grace;
- click or physical DOWN as explicit expansion;
- local `MediaGestureSession` with RIGHT previous, LEFT next, DOWN expand and expanded UP compact;
- one public AppKit arm haptic per horizontal armed transition;
- follow-finger interactive panel motion;
- compact/Peek bounded one-shot media capability and command work with zero persistent observer;
- expanded-only presentation-scoped shipping runtime;
- public `NSWorkspace` source-app icon badge with bounded cache;
- capability-gated draggable seek in Peek and expanded;
- source/track identity-locked seek cancellation;
- cursor ownership only during a valid seek, without warp/lock;
- bounded event-driven media/Home and horizontal-release continuity;
- dedicated Hover Peek cumulative artifact-size budget over immutable P0 while all prior budgets remain historical and unchanged.

The first physical candidate `d008f698b323963f084eedce601620ee957ef442` was rejected despite CI #872 success. Its defects were repaired under focused RED -> GREEN cycles.

Hover Peek then intentionally reopened deterministic size acceptance. CI #939 established exact evidence, CI #940 provided the clean missing-budget RED, and `745baa55b7a53519b3832f21305fa9c357ce05fa` / CI #944 passed both required jobs with `performance/m6-6-hover-peek-size-budget.json` active.

Acceptance ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

No P1 work, merge or release is allowed before the applicable physical gates pass on one exact docs-synchronized CI candidate.

## P1 — whole-app performance/resource review

Status: **AFTER M6.6 ACCEPTANCE / MERGE**.

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

1. Pass both required CI jobs on the docs-synchronized PR #33 head and freeze its exact source/artifacts.
2. Run the target-Mac M6.6 acceptance matrix across `NH-MEDIA-PEEK-*` and affected gesture/interactive/source-icon gates, including process teardown and permission checks.
3. If physical feel alone requires it, perform the single allowed visual travel/damping tuning pass with deterministic tests and a new exact candidate.
4. Only after full physical PASS: record evidence, mark PR #33 ready, merge and verify post-merge `main` CI.
5. Then start P1.
