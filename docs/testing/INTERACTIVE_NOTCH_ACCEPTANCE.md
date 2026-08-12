# M6.6 Interactive Notch Acceptance

Status: AUTOMATED-TESTED / PHYSICAL RETEST PENDING
Date: 2026-08-12
Primary target: macOS 26.6 / Mac16,8
Design: `docs/superpowers/specs/2026-08-12-interactive-notch-media-ux-design.md`

This ledger extends the frozen `NH-MEDIA-GESTURE-001...018` contract without renumbering it. PR #33 must remain draft until the exact repair candidate passes the target-Mac matrix.

## Stable gates

| ID | Gate | Required result |
|---|---|---|
| `NH-NOTCH-INTERACTIVE-001` | Compact downward tracking | Physical local downward gesture follows the finger from the current compact layout before release. |
| `NH-NOTCH-INTERACTIVE-002` | Compact cancellation | Short/reversed/cancelled downward gesture returns to exact compact and never starts persistent media observation. |
| `NH-NOTCH-INTERACTIVE-003` | Compact commit | Qualifying downward release settles through transition authority to exact expanded. |
| `NH-NOTCH-INTERACTIVE-004` | Expanded upward tracking | Physical local upward gesture follows the finger toward compact while expanded runtime remains authoritative until settlement. |
| `NH-NOTCH-INTERACTIVE-005` | Expanded cancel/commit | Cancel returns to exact expanded; qualifying release settles to compact and then releases runtime. |
| `NH-NOTCH-INTERACTIVE-006` | Arbitration + stale safety | Horizontal/seek capture cannot move the panel; momentum cannot drive it; stale layout/generation cannot restore obsolete geometry. |
| `NH-NOTCH-INTERACTIVE-007` | Hover parity | Existing 120 ms hover remains correct and does not steal a local compact gesture or duplicate haptics. |
| `NH-NOTCH-INTERACTIVE-008` | Reduce Motion | Physical tracking remains usable; endpoint settle follows Reduce Motion and lands exactly. |
| `NH-NOTCH-INTERACTIVE-009` | Resource lifecycle | Settled compact/cancelled expansion own zero persistent adapter; settled expanded owns the expected adapter; Quit leaves no orphan. |
| `NH-MEDIA-SOURCE-ICON-001` | Authoritative identity | Badge derives only from authoritative source bundle identifier. |
| `NH-MEDIA-SOURCE-ICON-002` | Correct/fallback rendering | Resolvable source shows its app icon; unresolved source shows a neutral app glyph. |
| `NH-MEDIA-SOURCE-ICON-003` | Text removal + accessibility | Persistent visual source text is absent while source identity remains available to accessibility/help semantics. |
| `NH-MEDIA-SOURCE-ICON-004` | Local bounded lookup | Public `NSWorkspace` only; no network/persistence/crawl; in-memory cache capped at 8 bundle identifiers. |

## First physical candidate result

Candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 was **not accepted**. Target testing found:

- compact horizontal/vertical input losing to pending hover expansion;
- physical vertical direction inverted relative to the approved down=open / up=close contract;
- seek transaction could survive a track/source change and seek the new track;
- horizontal media release and transient media/Home changes felt abrupt or flashed;
- lifecycle checks `NH-MEDIA-GESTURE-012` and `016` still needed explicit target execution.

The candidate is superseded. Its passing automated CI is historical evidence only.

## Repair implementation evidence

Strict RED -> GREEN cycles in PR #33:

- physical-axis/hover RED `0fd1f8de00ceb1d470c8e83d910356853dd72844`, CI #873;
- axis normalization `1f4bc0491b3f8a00d8d48b3763ec308f7b39a91b`, CI #874, leaving the independent hover RED;
- hover/gesture arbitration GREEN `1d4937b0467e290eb83033e4762a0bc406d00345`, CI #875;
- seek identity RED `3590640bfa73dfa3b672178111fe3d28e64e6705`, CI #876;
- seek identity GREEN `4c716880dc1e94ce7e1e168d3205d20bc2bfa7e4`, CI #877, with only the previous size envelope failing;
- continuity RED `812230ba8c73dd8b85e61ed0030be747ba5cef12`, CI #878;
- continuity implementation `d9fe5887c06d6e87402d25f403cb42a7b7102e75` plus Hashable/test-only follow-ups; final functional source `d8fb784eb9eb47c7af34dbd689b6fcfa5aadef12`, CI #881: 277 Swift tests and all functional/security/signing/preflight checks PASS, old size budget only RED;
- size-policy RED `38f73eaa3d13f25743ddaf831a5c66c3aba9fb78`, CI #882: 278 tests / 60 suites with exactly the missing repair budget failing;
- size-policy GREEN `6403dae0e33281f6dcd5bcbd79ec5147b6580c0a`, CI #883: both required jobs PASS.

Repair behavior is automated-tested, not physically accepted.

## Focused physical retest

Use only the final docs-sync exact candidate produced after this ledger update. At minimum retest:

1. Short horizontal swipe/reversal: no command/haptic, no stuck visual state.
2. Compact RIGHT -> previous; compact LEFT -> next; hover must not pre-empt the gesture.
3. Expanded RIGHT -> previous; LEFT -> next; visual offset settles smoothly.
4. Physical compact DOWN -> follow-finger expand; physical expanded UP -> follow-finger collapse.
5. Seek drag -> change track/source -> release: drag must cancel and must not seek the new track.
6. Hover regression: ordinary deliberate hover still opens normally.
7. Source icon regression for Yandex Music and Yandex Browser/Chromium.
8. No Accessibility/Input Monitoring/Automation/Screen Recording prompts.
9. After compact gesture work and after normal Quit:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: empty output.

One explicit target-Mac tuning pass may adjust only visual travel/damping. Frozen semantic thresholds and direction mapping are not silently changed.

## Acceptance rule

Do not mark M6.6 accepted, merge PR #33, start P1, or publish a release until all applicable `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact CI-produced candidate.
