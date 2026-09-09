# Roadmap

Primary product target: **native macOS / macOS 26.6**. NotchHub is a personal-use productivity hub centered on the MacBook notch.

Current published Personal Release: **v0.5.0**. Checked-in `VERSION` is **0.6.0** and v0.6.0 release preparation is merged, but publication is still pending. Historical releases remain immutable.

From M2.1 onward the default lifecycle is:

**implemented → automated-accepted → merged → released**

Automation is the default acceptance gate. Physical checks are optional diagnostics unless a future feature specification explicitly makes one mandatory.

## Product principles

- native macOS behavior and system APIs first;
- least privilege, App Sandbox and Hardened Runtime;
- no telemetry;
- no network access unless a future feature explicitly requires and reviews it;
- event-driven architecture instead of unjustified polling;
- low CPU/RSS/thread/energy overhead;
- multi-monitor behavior is a first-class real scenario;
- small independently testable PRs and frequent Personal Releases;
- never treat implemented, merged and released as synonyms.

## Current state

### Foundation / media / product shell

- **M0 Engineering Foundation — MERGED**
- **R0.1 Personal Release — RELEASED (`v0.1.0`)**
- **Performance Foundation — MERGED / RELEASED through subsequent versions**
- **M1 Active-display / multi-monitor foundation — MERGED**
- **M6 Media foundation and media-first UI — MERGED / RELEASED through `v0.4.0`**
- **M7 Settings shell — RELEASED (`v0.5.0`)**
- **v0.6.0 Shelf release preparation — MERGED / PUBLICATION PENDING**

Detailed historical evidence remains in `docs/testing/`, `docs/superpowers/`, release notes and the changelog.

### M2 Shelf

#### M2.1 Shelf Foundation — AUTOMATED-ACCEPTED / MERGED / RELEASE PENDING

Merged via PR #88 as `b0c1cf2f1054e754174099c31b1684f1742a11b2`.

Implemented scope:

- Expanded Home ↔ Shelf routing;
- Shelf access while media is active in Expanded;
- native file/folder multi-select picker;
- local file-URL drag/drop;
- persistent read-only security-scoped bookmarks;
- duplicate suppression and stale bookmark refresh;
- Open / Show in Finder / Remove-reference;
- actor-backed atomic persistence;
- exact least-privilege shipping entitlement set;
- external-app XCUI routing/reset coverage;
- provenance-backed size/performance gates.

Final automated acceptance: CI #1460 / run `34267057068` on PR head `7f2a17cd39f15ec395560866c8d61e0c4cf9d5bf`.

v0.6.0 release preparation for M2.1 was merged via PR #90 as `cc023e4720ae733770a8e9fe7926c514d0ab3fdf`; the GitHub Release/tag is still pending.

#### M2.2 Shelf Quick Look — IMPLEMENTED / AUTOMATED-ACCEPTED / PR #91

Bounded native usability slice:

- one Preview action per Shelf item;
- native macOS `QLPreviewPanel`;
- one explicitly owned read-only security scope while preview is active;
- scope cleanup on panel close, replacement, controller close and application termination;
- failed replacement closes the previous preview before acquiring the next scope, preventing stale preview content without access authority;
- existing bookmark resolution and unavailable-state handling reused;
- no entitlement, persistence-schema, network, polling, global-input or source-file-mutation expansion.

Automated acceptance on production head `6488e1f84cfad08c0fc557db4c811ae87c069dce`: CI #1473 / run `34284632091`, all three required jobs SUCCESS and all 497 Swift tests GREEN. Existing M2.1 size envelope remains sufficient.

PR #91 is not merged/released until GitHub evidence says so.

#### M2.3 Native Share / AirDrop — IMPLEMENTED / PRODUCTION CI GREEN / FINAL AUTOMATED ACCEPTANCE PENDING / PR #92

Bounded single-item native sharing slice stacked on M2.2:

- one Share action per persisted Shelf item;
- native macOS `NSSharingServicePicker` and system-provided sharing services, including AirDrop where available;
- existing read-only bookmark/security-scope boundary reused;
- exactly one explicitly owned read-only share scope at a time;
- cleanup on picker cancellation, sharing success/failure, replacement, controller close and application termination;
- previous picker/scope closed before replacement scope acquisition;
- Swift 6.3-safe separation between nonisolated picker-delegate callbacks and main-actor UI/state ownership;
- no `@preconcurrency` escape hatch;
- no custom AirDrop/network client or discovery protocol;
- no entitlement, persistence-schema, polling/timer, global-input, source-file-mutation or third-party-runtime expansion;
- no multi-selection in this slice.

Verified production candidate: `17d66ababca2a25c3c4294bd169ecbc46f8d1d25`, CI #1484 / run `34322638424`, all three required jobs SUCCESS. The existing M2.1 feature-size envelope remains sufficient.

Final automated acceptance requires the complete CI matrix on the exact PR head containing the M2.3 design, acceptance, security and roadmap documentation. PR #92 remains stacked on #91 and is not merged/released until the release/dependency ordering is resolved.

Defer broader Shelf selection/multi-selection, keyboard workflows and file-management operations until after the single-item daily-use path remains coherent and accepted.

### M3 Snippets — PLANNED

Own text/URL snippets, clipboard-oriented workflows and related persistence. Do not overload Shelf with M3 responsibilities.

### M4 Calendar — PLANNED

Calendar/event surface with permissions introduced only through a separately reviewed least-privilege design.

### M5 Translator — PLANNED

Translation surface. Network/model/provider architecture must be explicitly designed before any permission/network expansion.

## Delivery cadence

Prefer short vertical slices:

1. design/spec the bounded behavior;
2. write RED tests/policy gates;
3. implement minimal GREEN production code;
4. obtain full automated acceptance on the exact PR head;
5. merge to protected `main`;
6. publish a Personal Release frequently when the increment is useful and release metadata is ready;
7. immediately start the next bounded slice.

Do not batch unrelated features merely to reduce release count. Release frequency is a product goal, but security, correctness and resource budgets remain non-negotiable gates.

## Near-term sequence

1. Publish the prepared `v0.6.0` M2.1 release from exact protected `main` through the manual Personal Release workflow.
2. Merge automated-accepted PR #91 (M2.2 Quick Look) after v0.6.0 exists, then verify protected `main`.
3. Complete exact-head automated acceptance for PR #92 (M2.3 Share), retarget it to `main` after #91 merge, and reverify the changed merge base before merging.
4. Reassess whether Shelf's coherent minimal daily-use workflow is complete enough to begin M3 Snippets or whether one more bounded M2 usability slice has higher value.
