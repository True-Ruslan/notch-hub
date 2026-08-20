# P1 expanded-frame settlement repair

## Evidence

Target-Mac P1 manual compositor acceptance on Mac16,8 / macOS 26.6.1 / runtime `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251` exposed a persistent expanded-size panel showing the compact media surface around cycle 3.

The compact media surface is only selected by `NotchPanelModel.contentPresentation == .compact`. In the transition coordinator, `.compact` is published from the matching collapse completion. The coordinator currently trusts the AppKit animation completion as proof that the physical `NSPanel` frame reached the compact endpoint; it does not synchronously reconcile frame/corner before publishing compact content.

## Root-cause hypothesis

An interrupted or retargeted AppKit frame animation can reach its completion path without the physical window being at the expected endpoint. Generation checks prevent stale logical completions from winning, but a matching completion still has no physical-endpoint invariant. This permits `contentPresentation == .compact` while the panel remains physically expanded, after which normal compact pointer policy no longer produces a collapse for the already-compact logical state.

## Required invariant

For a matching current-generation transition completion:

1. Reconcile the exact physical frame and corner radius synchronously to the destination endpoint.
2. Only then publish the settled logical content presentation/phase.
3. Never reconcile an endpoint from a stale-generation completion.

## Scope constraints

- No polling, timers, display links, synthetic input, telemetry, networking, permissions, or entitlements.
- Keep public AppKit/Core Animation only.
- Preserve existing animation duration, haptic policy, multi-monitor layout selection, and interactive transition behavior.
- Use TDD: RED regression first, then the smallest settlement-boundary change.
- Physical acceptance remains required after automated CI; an automated pass does not erase the prior P1 anomaly.
