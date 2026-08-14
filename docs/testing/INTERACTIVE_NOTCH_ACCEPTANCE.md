# M6.6 Interactive Notch Acceptance

Status: AUTOMATED POINTER-EXIT REPAIR GREEN / PHYSICAL RETEST PENDING
Date: 2026-08-13
Primary target: macOS 26.6 / Mac16,8
Design: `docs/superpowers/specs/2026-08-12-interactive-notch-media-ux-design.md`

This ledger extends the frozen M6.6 media-gesture acceptance contract without renumbering or redefining its existing stable IDs. PR #33 remains draft until one exact CI-produced candidate passes the target-Mac matrix.

## Stable gates

| ID | Gate | Required result |
|---|---|---|
| `NH-NOTCH-INTERACTIVE-001` | Compact downward tracking | Physical local downward gesture follows the finger from current compact layout before release. If pointer/panel separation loses terminal local scroll delivery, transition settles safely to compact rather than remaining intermediate. |
| `NH-NOTCH-INTERACTIVE-002` | Compact cancellation | Short/reversed/cancelled downward gesture returns to exact compact and never starts persistent media observation. |
| `NH-NOTCH-INTERACTIVE-003` | Compact commit | Qualifying downward release settles through transition authority to exact expanded. |
| `NH-NOTCH-INTERACTIVE-004` | Expanded upward tracking | Physical local upward gesture follows the finger toward compact while expanded runtime remains authoritative until settlement. |
| `NH-NOTCH-INTERACTIVE-005` | Expanded cancel/commit + lost-terminal safety | Cancel returns to exact expanded; qualifying release settles to compact. Leaving expanded retention collapses non-haptically. If the shrinking panel moves out from under the pointer before `.ended`/`.cancelled`, the transition must retarget/settle to exact compact and never remain intermediate. |
| `NH-NOTCH-INTERACTIVE-006` | Arbitration + stale safety | Horizontal/seek capture cannot move the panel; momentum cannot drive it; stale layout/generation cannot restore obsolete geometry. Pointer-exit collapse is the sole fail-safe allowed to retarget an owned interactive transition. |
| `NH-NOTCH-INTERACTIVE-007` | Hover parity | Existing 120 ms media Hover Peek remains correct from stable compact and does not steal a local compact gesture or duplicate haptics. |
| `NH-NOTCH-INTERACTIVE-008` | Reduce Motion | Physical tracking remains usable; endpoint settle follows Reduce Motion and lands exactly. |
| `NH-NOTCH-INTERACTIVE-009` | Resource lifecycle | Settled compact/cancelled or pointer-exit-retargeted expansion own zero persistent adapter; settled expanded owns the expected adapter; Quit leaves no orphan. |
| `NH-MEDIA-SOURCE-ICON-001` | Authoritative identity | Badge derives only from authoritative source bundle identifier. |
| `NH-MEDIA-SOURCE-ICON-002` | Correct/fallback rendering | Resolvable source shows its app icon; unresolved source shows a neutral app glyph. |
| `NH-MEDIA-SOURCE-ICON-003` | Text removal + accessibility | Persistent visual source text is absent while source identity remains available to accessibility/help semantics. |
| `NH-MEDIA-SOURCE-ICON-004` | Local bounded lookup | Public `NSWorkspace` only; no network/persistence/crawl; in-memory cache capped at 8 bundle identifiers. |

## Latest physical rejection

Exact candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but failed target testing.

Observed:

- expanded did not auto-collapse after pointer exit, regressing the previously accepted M1 contract;
- physical UP could leave the panel at a clipped intermediate frame when geometry moved away from the pointer before the local hosting view received the terminal scroll phase;
- hover/haptic/Peek was also absent in the observed broken session and must be retested after the ownership repair from clean stable compact.

Code inspection confirmed that PR #33 had changed expanded pointer policy to retain `.expanded` unconditionally. It also confirmed that interactive settlement depended on local `.ended`/`.cancelled`, which can be lost after the shrinking panel leaves the pointer.

## Focused TDD repair

- RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959: 333 tests / 69 suites with exactly five new pointer-exit/lost-terminal regression tests failing; pre-existing suite passed;
- GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`: restored expanded retention collapse, made `.pointerExitCollapse` the sole interactive-retarget exception, passed the current `NSEvent.mouseLocation` through the local scroll path, and used actual `panel.frame` to settle when geometry leaves the pointer;
- format-only `de5624b7d344e15772fdf0759fbe4b5027a5b1d4` / CI #961: both required jobs PASS, 333 tests / 69 suites PASS and all strict security/performance/media/signing/preflight/size/performance-smoke gates PASS.

The repair adds no global scroll monitor, event tap, watchdog timer, polling loop, display link or sensitive input permission.

## Focused physical retest

Use only the final docs-synchronized candidate frozen in PR #33 after its exact head passes CI.

1. Stable compact + usable media: hover must open Peek with expected haptic; hover alone must not open full Home.
2. DOWN -> exact expanded; then simply leave expanded retention with the pointer. It must auto-collapse non-haptically to exact compact.
3. DOWN -> expanded, then perform UP while keeping the pointer relatively stationary so the shrinking panel moves away from it before the gesture terminates. No intermediate frame may remain.
4. Repeat UP while deliberately moving the pointer outside during the owned gesture. Require exact compact.
5. Begin compact DOWN and separate pointer/panel before terminal delivery. Require safe return to compact, not a stuck partial expansion.
6. Repeat these transition cycles several times before continuing horizontal gestures, seek, source icon and lifecycle checks.

## Acceptance rule

Do not mark M6.6 accepted, merge PR #33, start P1, or publish a release until all applicable `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-PEEK-*`, and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact CI-produced candidate.
