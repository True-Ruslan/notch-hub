# M6.6 Interactive Notch Acceptance

Status: AUTOMATED-GREEN THROUGH CI #1238 / FINAL HORIZONTAL PHYSICAL SMOKE CONFIRMED ON `f2e81d993...` / FULL INTERACTIVE ONE-SHA PHYSICAL MATRIX PENDING
Date: 2026-08-18
Primary target: macOS 26.6 / Mac16,8
Design: `docs/superpowers/specs/2026-08-12-interactive-notch-media-ux-design.md`
Repair addendum: `docs/superpowers/specs/2026-08-15-no-media-hover-peek-physical-repair.md`

This ledger extends the frozen M6.6 media-gesture acceptance contract without renumbering existing stable IDs. PR #33 remains draft until one exact CI-produced candidate passes the complete applicable target-Mac matrix.

## Stable gates

| ID | Gate | Required result | Current physical status |
|---|---|---|---|
| `NH-NOTCH-INTERACTIVE-001` | Compact downward tracking | Physical local DOWN follows the finger from current compact layout before release; exact top-screen/panel `maxY` remains valid; lost terminal delivery cannot leave intermediate geometry. | Basic DOWN smoke physically confirmed on `f2e81d993...`; exact-edge/full gate PENDING |
| `NH-NOTCH-INTERACTIVE-002` | Compact cancellation | Short/reversed/cancelled DOWN returns to exact compact and never starts persistent media observation. | PENDING |
| `NH-NOTCH-INTERACTIVE-003` | Compact commit | Qualifying downward release settles through transition authority to exact expanded. | Basic DOWN smoke physically confirmed on `f2e81d993...`; full gate PENDING |
| `NH-NOTCH-INTERACTIVE-004` | Expanded upward tracking | Physical local UP follows the finger toward compact while expanded runtime remains authoritative until settlement. | Basic UP smoke physically confirmed on `f2e81d993...`; full tracking gate PENDING |
| `NH-NOTCH-INTERACTIVE-005` | Expanded cancel/commit + lost-terminal safety | Cancel returns to exact expanded; qualifying release/pointer exit settles to exact compact; moving geometry never remains intermediate. | Basic UP smoke physically confirmed on `f2e81d993...`; pointer-exit/lost-terminal matrix PENDING |
| `NH-NOTCH-INTERACTIVE-006` | Arbitration + stale safety | Horizontal/seek capture cannot move panel; momentum cannot drive it; stale layout/generation cannot restore obsolete geometry. | Horizontal momentum no-extra-switch smoke physically confirmed on `f2e81d993...`; full arbitration PENDING |
| `NH-NOTCH-INTERACTIVE-007` | Hover parity | Existing 120 ms Hover Peek remains correct from stable compact, including generic no-media Peek, and does not steal a local compact gesture or duplicate haptics. | PENDING final exact-head hover matrix |
| `NH-NOTCH-INTERACTIVE-008` | Reduce Motion | Physical tracking remains usable; endpoint settle follows Reduce Motion and lands exactly. | PENDING |
| `NH-NOTCH-INTERACTIVE-009` | Resource lifecycle | Settled compact/cancelled or pointer-exit-retargeted expansion own zero persistent adapter; settled expanded owns expected adapter; Quit leaves no orphan. | PENDING explicit final lifecycle evidence |
| `NH-MEDIA-SOURCE-ICON-001` | Authoritative identity | Badge derives only from authoritative source bundle identifier. | PENDING final source matrix |
| `NH-MEDIA-SOURCE-ICON-002` | Correct/fallback rendering | Resolvable source shows its app icon; unresolved source shows a neutral app glyph. | PENDING |
| `NH-MEDIA-SOURCE-ICON-003` | Text removal + accessibility | Persistent visual source text is absent while source identity remains available to accessibility/help semantics. | PENDING |
| `NH-MEDIA-SOURCE-ICON-004` | Local bounded lookup | Public `NSWorkspace` only; no network/persistence/crawl; in-memory cache capped at 8 bundle identifiers. | PENDING physical confirmation; automated policy GREEN |

## Physical rejection history retained

### Candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951

Rejected on Mac16,8/macOS 26.6 because expanded pointer exit regressed, physical UP could leave an intermediate clipped frame and Hover Peek/haptic was absent in the observed session. Subsequent focused regressions restored pointer-exit and lost-terminal settlement without global scroll capture.

### Candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101

Rejected because exact-top-edge DOWN twitched and returned to compact and no-media hover produced neither Peek nor physical haptic. The exact-edge root cause was half-open raw `CGRect.contains` semantics; interactive ownership now uses inclusive `NotchPointerPolicy.containsInteractivePointer`. Generic no-media Peek was added without widening hover activation geometry or adding new input authority.

## Current automated evidence

Exact source `f2e81d993db37af9548799682ad8f03c7d64ae27` / CI #1238 / run `32072408370` is 3/3 GREEN with 365 Swift tests / 79 suites, external exact-app XCUI 11/11, strict traceability, production transport/archive, source/security policy, Sandbox/Hardened Runtime/signing/preflight, current cumulative size budget and shared-runner performance smoke.

The target Mac physically confirmed on this exact source that RIGHT/LEFT horizontal direction and follow-finger visuals are correct, horizontal haptic is felt once, momentum produces no extra media switch and basic DOWN/UP smoke remains correct. These are useful interaction smoke results but do not replace the exact-edge, pointer-exit, lost-terminal, Reduce Motion, resource and source-icon gates above.

## Regression coverage retained

- exact `maxY` inclusive-pointer tests protect the physical top boundary;
- generic no-media hover tests protect Peek activation independent of media availability;
- local `NSTrackingArea` remains the primary event-driven hover source;
- explicit expansion uses the stable parent SwiftUI tap recognizer;
- transition tests protect pointer-exit/lost-terminal exact settlement;
- the new `MediaGesturePhysicalPipelineTests` protects raw horizontal input -> normalization -> visual -> media command across both macOS scroll-direction preference states.

The repair adds no global scroll monitor, mouse-button monitor, event tap, watchdog timer, polling loop, display link or sensitive input permission.

## Final focused physical matrix

Use only the next exact test/documentation head after its canonical CI is 3/3 GREEN.

1. Music OFF: hover from stable compact -> generic Peek + one physical haptic; hover alone never expands.
2. Relaunch with pointer already stationary over the notch -> same Peek/haptic without leave/re-enter.
3. Normal compact click while hover is eligible -> expanded exactly once; dwell may not swallow the click.
4. Pointer fully against the physical top screen edge + DOWN -> stable follow-finger expansion, no twitch/self-collapse.
5. Repeat DOWN slightly lower near notch center.
6. From expanded simply leave retention -> non-haptic exact compact.
7. Expand and perform UP with relatively stationary pointer -> exact compact even if shrinking geometry moves away before terminal delivery.
8. Repeat UP while deliberately moving outside -> exact compact.
9. Verify Reduce Motion endpoint behavior if enabled/available.
10. Verify source icon/fallback/accessibility identity behavior.
11. After real Quit verify `pgrep -lf 'mediaremote-adapter\.pl' || true` is empty and the permission matrix remains NONE.

## Acceptance rule

Do not mark M6.6 accepted, merge PR #33, start P1 or publish a release until all applicable `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-PEEK-*`, and `NH-MEDIA-SOURCE-ICON-*` gates pass on one final exact CI-produced candidate.
