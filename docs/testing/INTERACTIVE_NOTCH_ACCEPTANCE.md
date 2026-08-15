# M6.6 Interactive Notch Acceptance

Status: AUTOMATED PHYSICAL-REPAIR GREEN / FINAL DOCS-SYNC CI PENDING / PHYSICAL RETEST PENDING
Date: 2026-08-15
Primary target: macOS 26.6 / Mac16,8
Design: `docs/superpowers/specs/2026-08-12-interactive-notch-media-ux-design.md`
Repair addendum: `docs/superpowers/specs/2026-08-15-no-media-hover-peek-physical-repair.md`

This ledger extends the frozen M6.6 media-gesture acceptance contract without renumbering existing stable IDs. PR #33 remains draft until one exact CI-produced candidate passes the target-Mac matrix.

## Stable gates

| ID | Gate | Required result |
|---|---|---|
| `NH-NOTCH-INTERACTIVE-001` | Compact downward tracking | Physical local DOWN follows the finger from current compact layout before release. A pointer exactly against the physical top screen/panel `maxY` boundary is valid and must not trigger false pointer-exit self-collapse. If pointer/panel separation loses terminal local scroll delivery, transition settles safely to compact rather than remaining intermediate. |
| `NH-NOTCH-INTERACTIVE-002` | Compact cancellation | Short/reversed/cancelled DOWN returns to exact compact and never starts persistent media observation. |
| `NH-NOTCH-INTERACTIVE-003` | Compact commit | Qualifying downward release settles through transition authority to exact expanded. |
| `NH-NOTCH-INTERACTIVE-004` | Expanded upward tracking | Physical local UP follows the finger toward compact while expanded runtime remains authoritative until settlement. |
| `NH-NOTCH-INTERACTIVE-005` | Expanded cancel/commit + lost-terminal safety | Cancel returns to exact expanded; qualifying release settles to compact. Leaving expanded retention collapses non-haptically. If shrinking geometry moves away before `.ended`/`.cancelled`, transition retargets/settles to exact compact and never remains intermediate. |
| `NH-NOTCH-INTERACTIVE-006` | Arbitration + stale safety | Horizontal/seek capture cannot move the panel; momentum cannot drive it; stale layout/generation cannot restore obsolete geometry. Pointer-exit collapse is the sole fail-safe allowed to retarget an owned interactive transition. |
| `NH-NOTCH-INTERACTIVE-007` | Hover parity | Existing 120 ms Hover Peek remains correct from stable compact, including generic no-media Peek, and does not steal a local compact gesture or duplicate haptics. |
| `NH-NOTCH-INTERACTIVE-008` | Reduce Motion | Physical tracking remains usable; endpoint settle follows Reduce Motion and lands exactly. |
| `NH-NOTCH-INTERACTIVE-009` | Resource lifecycle | Settled compact/cancelled or pointer-exit-retargeted expansion own zero persistent adapter; settled expanded owns the expected adapter; Quit leaves no orphan. |
| `NH-MEDIA-SOURCE-ICON-001` | Authoritative identity | Badge derives only from authoritative source bundle identifier. |
| `NH-MEDIA-SOURCE-ICON-002` | Correct/fallback rendering | Resolvable source shows its app icon; unresolved source shows a neutral app glyph. |
| `NH-MEDIA-SOURCE-ICON-003` | Text removal + accessibility | Persistent visual source text is absent while source identity remains available to accessibility/help semantics. |
| `NH-MEDIA-SOURCE-ICON-004` | Local bounded lookup | Public `NSWorkspace` only; no network/persistence/crawl; in-memory cache capped at 8 bundle identifiers. |

## Physical rejection history

### Candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951

Rejected on Mac16,8/macOS 26.6:

- expanded did not auto-collapse after pointer exit, regressing accepted M1 behavior;
- physical UP could leave the panel at a clipped intermediate frame when geometry moved away before the local hosting view received the terminal scroll phase;
- hover/haptic/Peek was absent in the observed broken session.

Focused RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959 reproduced pointer-exit/lost-terminal regressions. GREEN restored accepted expanded retention collapse and synchronous actual-frame settlement without global scroll capture.

### Candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101

Rejected on 2026-08-15 with media off:

- expanded pointer exit -> compact remained PASS;
- UP collapse remained stable;
- DOWN from near the notch center was stable;
- **DOWN started with the pointer completely against the physical top screen edge twitched downward and immediately returned to compact**;
- hover produced neither Peek nor a physical haptic.

The exact-edge root cause was half-open raw `CGRect.contains` semantics. Interactive ownership now uses inclusive `NotchPointerPolicy.containsInteractivePointer`, covered by focused regression tests. No normal hover-region expansion or new input authority was added.

## 2026-08-15 automated repair evidence

- exact `maxY` regression coverage proves the physical top boundary remains inside interactive ownership;
- no-media hover coverage proves Peek activation is not gated by media availability;
- local `NSTrackingArea` is the primary event-driven hover source;
- explicit expansion uses a stable parent SwiftUI tap recognizer across compact/Peek, avoiding the hover-dwell click race without adding mouse-button monitoring;
- `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155`: 352 Swift tests / 74 suites PASS and 11/11 external XCUI journeys PASS; package failed only the previous DMG ceiling;
- `3e617698a503590dbc18958960a5335753734ccc` / CI #1147 / run `31889961194`: all three canonical jobs PASS, including security/source audit and the minimal updated cumulative size budget.

The repair adds no global scroll monitor, mouse-button monitor, event tap, watchdog timer, polling loop, display link or sensitive input permission.

## Focused physical retest

Use only the final docs-synchronized candidate frozen in PR #33 after its exact head passes CI.

1. Music OFF: hover from stable compact -> generic Peek + one physical haptic; hover alone must never open full expanded.
2. Relaunch with the pointer already stationary over the physical notch -> same Peek/haptic without leave/re-enter.
3. Normal compact click while hover is eligible -> expanded exactly once; dwell may not swallow the click.
4. Put the pointer fully against the top screen edge and perform DOWN -> stable follow-finger expansion, no twitch/self-collapse.
5. Repeat DOWN slightly lower near notch center -> same stable behavior.
6. From expanded, simply leave retention with the pointer -> non-haptic exact compact.
7. Expand and perform UP with a relatively stationary pointer -> exact compact even if shrinking geometry moves away before terminal delivery.
8. Repeat UP while deliberately moving outside -> exact compact.
9. Repeat cycles several times before continuing horizontal gestures, seek, source icon, lifecycle and permission checks.

## Acceptance rule

Do not mark M6.6 accepted, merge PR #33, start P1, or publish a release until all applicable `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-PEEK-*`, and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact CI-produced candidate.
