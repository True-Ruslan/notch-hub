# M6.6 Interactive Notch Acceptance

Status: ACCEPTED ON EXACT SOURCE `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / CI #1241 3/3 GREEN / NOT MERGED / NOT RELEASED
Date: 2026-08-18
Primary target: macOS 26.6 / Mac16,8
Design: `docs/superpowers/specs/2026-08-12-interactive-notch-media-ux-design.md`
Repair addendum: `docs/superpowers/specs/2026-08-15-no-media-hover-peek-physical-repair.md`

This ledger extends the frozen M6.6 media-gesture contract without renumbering stable IDs. Deterministic state-machine properties are accepted through automated regressions; physical notch-edge, follow-finger, compositor, source-icon and process/permission properties are tied to the exact target-Mac candidate.

## Stable gates

| ID | Gate | Required result | Acceptance evidence |
|---|---|---|---|
| `NH-NOTCH-INTERACTIVE-001` | Compact downward tracking | Physical local DOWN follows the finger from compact; exact top-screen/panel `maxY` is valid; lost terminal delivery cannot leave intermediate geometry. | PASS — exact-edge/center physical DOWN + inclusive pointer/interactive transition regressions. |
| `NH-NOTCH-INTERACTIVE-002` | Compact cancellation | Short/reversed/cancelled DOWN returns exact compact and never starts persistent media observation. | PASS — deterministic cancellation/lifecycle regressions; no separate physical-only requirement. |
| `NH-NOTCH-INTERACTIVE-003` | Compact commit | Qualifying downward release settles through transition authority to exact expanded. | PASS — deterministic endpoint regression + final physical DOWN matrix. |
| `NH-NOTCH-INTERACTIVE-004` | Expanded upward tracking | Physical local UP follows toward compact while expanded runtime remains authoritative until settlement. | PASS — interactive collapse regression + final physical UP matrix. |
| `NH-NOTCH-INTERACTIVE-005` | Expanded cancel/commit + lost-terminal safety | Cancel returns exact expanded; qualifying release/pointer exit settles exact compact; moving geometry never remains intermediate. | PASS — cancellation/pointer-exit regressions + final pointer-exit/UP physical matrix. |
| `NH-NOTCH-INTERACTIVE-006` | Arbitration + stale safety | Horizontal/seek capture cannot move panel; momentum cannot drive it; stale layout/generation cannot restore obsolete geometry. | PASS — deterministic arbitration/stale regressions; no separate physical-only requirement. |
| `NH-NOTCH-INTERACTIVE-007` | Hover parity | 120 ms Hover Peek works from stable compact, including generic no-media Peek, without stealing local gesture or duplicating haptics. | PASS — automated dwell/hold regressions + media/no-media/stationary physical Hover Peek matrix. |
| `NH-NOTCH-INTERACTIVE-008` | Reduce Motion | Physical tracking remains usable; endpoint settle follows Reduce Motion and lands exactly. | PASS — deterministic Reduce Motion duration/retarget regressions; physical-only retest not required because final hardware matrix did not alter this policy. |
| `NH-NOTCH-INTERACTIVE-009` | Resource lifecycle | Settled compact/cancelled or pointer-exit-retargeted expansion own zero persistent adapter; settled expanded owns expected adapter; Quit leaves no orphan. | PASS — lifecycle policy/transport regressions + empty post-Quit `pgrep` on exact candidate. |
| `NH-MEDIA-SOURCE-ICON-001` | Authoritative identity | Badge derives only from authoritative source bundle identifier. | PASS — source identity/policy tests + final real-source matrix. |
| `NH-MEDIA-SOURCE-ICON-002` | Correct/fallback rendering | Resolvable source shows its app icon; unresolved source shows a neutral app glyph. | PASS — composition regression + target-Mac source icon/fallback check. |
| `NH-MEDIA-SOURCE-ICON-003` | Text removal + accessibility | Persistent visual source text is absent while source identity remains available to accessibility/help semantics. | PASS — deterministic composition/accessibility policy tests. |
| `NH-MEDIA-SOURCE-ICON-004` | Local bounded lookup | Public `NSWorkspace` only; no network/persistence/crawl; in-memory cache capped at 8 bundle identifiers. | PASS — deterministic resolver/composition policy tests. |

## Exact physical evidence

Canonical source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / CI #1241 / run `32075976405` passed 366 Swift tests / 80 suites and external exact-app XCUI 11/11.

The 2026-08-18 Mac16,8/macOS 26.6 final matrix confirmed:

- exact physical top-edge DOWN and center DOWN follow-finger expansion with no twitch/self-collapse;
- expanded pointer exit returns exact compact;
- physical UP returns exact compact, including while the pointer leaves retention;
- media/no-media Hover Peek and stationary-pointer relaunch produce expected physical haptic without hover-only expansion;
- source icon and fallback render correctly;
- real Quit leaves no `mediaremote-adapter.pl` process;
- Accessibility, Input Monitoring, Automation and Screen Recording remain NONE.

Reduce Motion, cancellation, stale-generation and arbitration properties are deterministic and remain accepted by the existing automated suite rather than being falsely described as new physical evidence.

## Historical rejection evidence

Earlier candidates exposed stationary-start hover, expanded pointer-exit/lost-terminal, no-media Peek and exact-top-edge defects. Those failures remain historical evidence for their exact SHAs. The final exact candidate passed the repaired physical paths and the automated regressions prevent those known failure classes from silently returning.

## Acceptance provenance

Physical acceptance remains pinned to runtime source `8744b9e...`. The follow-up acceptance-record commit changes only docs/coverage metadata. PR #33 remains Draft / not merged / not released until a separate merge decision.
