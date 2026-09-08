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

#### M2.3 Native Share / AirDrop — NEXT DESIGN SLICE

Preferred next Shelf increment after M2.2 merge:

- native macOS share services for one explicitly selected Shelf item;
- AirDrop exposed through system share infrastructure where available;
- reuse the existing bookmark/security-scope boundary;
- keep source file read-only and untouched;
- no custom network client or discovery protocol;
- no broad entitlement expansion;
- no multi-selection unless it is separately justified by the design.

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

1. Finish PR #91 documentation/final verification and merge M2.2 after exact-head CI remains GREEN.
2. Publish prepared `v0.6.0` from exact protected `main` through the manual Personal Release workflow if it has not already been published before that point.
3. Design M2.3 as a bounded native Share/AirDrop slice.
4. Continue M2 in small increments or start M3 when Shelf has a coherent minimal daily-use workflow.
