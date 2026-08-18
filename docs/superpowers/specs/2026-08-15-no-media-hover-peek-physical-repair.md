# No-media Hover Peek physical-repair addendum

Status: APPROVED PHYSICAL-ACCEPTANCE REPAIR / AUTOMATED GREEN / PHYSICAL RETEST PENDING
Date: 2026-08-15
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33

## Decision

The 2026-08-15 target-Mac rejection changes one pending Hover Peek product assumption:

> A valid compact hover dwell opens lightweight Peek even when no usable media session exists.

Usable media is now an enrichment source, not an activation prerequisite.

This addendum supersedes the no-media statements in `2026-08-12-hover-peek-media-interaction-design.md` wherever that document says no media must remain compact, Peek exists only with media, or no-media hover must produce no haptic. All unrelated interaction, security, performance and lifecycle constraints remain in force.

## Required behavior

- Hover dwell remains exactly 120 ms.
- After a valid dwell, transition `compact -> peek` occurs immediately through the existing panel transition authority.
- Hover requests the existing Peek haptic exactly once.
- Hover alone never opens full `expanded` UI.
- One bounded media probe may run after Peek activation.
- A positive media result enriches Peek in place.
- `.noSession` leaves a generic lightweight Peek; it does not collapse merely because media is absent.
- A stale/cancelled probe cannot create or mutate obsolete presentation state.
- Compact and Peek still own zero persistent media observer.
- Pointer exit and the existing 140 ms Peek grace remain unchanged.
- Explicit click or physical DOWN from compact/Peek still opens expanded.

## Generic Peek

When media is absent, Peek is a lightweight interaction affordance rather than fabricated playback state. It must not invent title, artist, artwork, source identity, timeline position or media capabilities.

Generic Peek may use neutral presentation only. Persistent media controls remain capability-driven; unavailable media actions must not be presented as working transport commands.

## Exact top-edge interaction repair

The same physical test exposed a geometry boundary defect. A pointer exactly on the physical top screen/panel `maxY` boundary must count as inside the interactive panel during DOWN expansion. Interactive pointer containment therefore uses an inclusive boundary policy instead of raw half-open `CGRect.contains` semantics for this ownership check.

This change is limited to interactive ownership/settlement. It does not enlarge the normal hover region or introduce a global input source.

## Click versus hover dwell

Native XCUI reproduced a click race: moving the pointer to compact for a click can consume approximately one hover dwell before the click completes. If a tap recognizer belongs to a child that is replaced by the compact-to-Peek state switch, the click can be lost.

The approved solution is one stable SwiftUI tap recognizer above the compact/Peek presentation switch. It expands from either compact or Peek and is ignored once already expanded.

Rejected solution: introducing new `.leftMouseDown` authority in `NSPanel` or a new local/global mouse-button monitor. Existing security policy correctly rejected that approach; it was removed.

## Haptic policy

- hover-to-Peek: one existing hover haptic, including generic no-media Peek;
- horizontal supported arm: existing one-shot `.levelChange` semantics;
- vertical DOWN/UP: no new haptic;
- cancelled/stale hover: no haptic;
- no duplicate haptic for one hover activation.

Automated UI diagnostics may verify that the application requests the haptic through the production transition boundary. Actual trackpad vibration remains physical-only acceptance.

## Input architecture

Primary hover delivery uses local `NSTrackingArea` entry/move/exit events. The already-reviewed narrow `.mouseMoved` fallback remains until later P1 comparison. This repair adds no:

- global scroll monitor;
- global/local mouse-button monitor;
- `CGEventTap`;
- Accessibility/Input Monitoring/Automation/Screen Recording permission;
- polling or repeating timer;
- display link;
- pointer warp/lock in production.

## Automated acceptance requirements

At minimum the regression suite must prove:

1. no-media hover eligibility does not depend on a media result;
2. generic Peek appears after hover and expanded does not;
3. exactly one haptic request accompanies the activation;
4. a stationary pointer over the notch after relaunch remains eligible without extra movement;
5. exact top-edge interactive containment is inclusive;
6. normal compact click still expands when hover dwell overlaps the click;
7. expanded pointer exit still returns to compact;
8. shipping binaries exclude compile-time UI fixtures/diagnostics;
9. security/source policy rejects any newly introduced mouse-button monitor/event-tap authority.

## Acceptance boundary

Automated GREEN is necessary but not sufficient. Mac16,8/macOS 26.6 must physically confirm generic no-media Peek, physical haptic, stationary relaunch, explicit click, exact-edge DOWN, pointer-exit collapse and UP settlement on one exact CI-produced candidate before the affected M6.6 gates can be accepted.
