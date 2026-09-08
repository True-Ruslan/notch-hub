# Releasing NotchHub

Versioned builds are distributed through GitHub Releases. Raw CI artifacts are development/verification outputs, not published releases.

NotchHub currently uses a **Personal Release** tier for private use without paid Apple Developer membership. A **Trusted Release** tier with Developer ID/notarization remains optional for the future.

## Release state model

From 2026-09-08 onward the project lifecycle is:

**implemented → automated-accepted → merged → released**

A merge does not automatically create a release. A release must point at accepted merged code and pass the release workflow's artifact/provenance checks.

## 1. Personal Release — current default

Canonical workflow: **Actions → Personal Release → Run workflow**, branch `main`.

Before creating a versioned release:

1. `VERSION` and changelog/release notes describe the intended version;
2. the release commit is in protected `main`;
3. mandatory CI is green for the exact source candidate used by the release;
4. source security/performance policies are green;
5. shipping entitlement, signing, Hardened Runtime and provenance checks are green;
6. deterministic artifact-size budget and performance compatibility smoke are green.

The Personal Release workflow must fail closed on version/tag/provenance mismatches. Existing published tags/releases are immutable historical evidence: never replace a failed artifact under an existing version. Fix the issue and increment the version.

Personal Release artifacts may require the standard macOS user approval path because they are not Developer-ID notarized. This is an accepted constraint of the current private-use distribution tier, not permission to weaken Sandbox/Hardened Runtime or provenance checks.

## 2. Automated release acceptance

For personal-use NotchHub, physical acceptance is no longer a mandatory release blocker by default.

The release is accepted when the exact release candidate passes all repository-defined automated gates applicable to that version, including:

- protected-branch CI;
- release/version policy;
- build/tests and warnings-as-errors;
- external-app XCUITest for deterministic user-visible flows;
- security audit and exact effective entitlements;
- code-signing/Hardened Runtime/bundle/DMG verification;
- source/artifact provenance;
- active provenance-backed size budget;
- performance compatibility smoke.

If any mandatory check fails, do not publish or replace an existing release artifact.

## 3. Manual/physical spot checks

`NH-PERSONAL-RELEASE-001` is retained as a historical/manual personal-release spot-check identifier. Starting 2026-09-08 it is optional diagnostic evidence for new personal releases, not a release gate.

A manual check can still be useful for subjective notch geometry, pointer/trackpad feel, haptics, external applications and hardware-specific behavior. A discovered defect should be fixed in a new commit/version and, when deterministic, converted into automated coverage.

Historical release documents that record mandatory physical acceptance remain valid descriptions of the policy that applied when those releases were produced.

## 4. Trusted Release — optional future tier

If Apple Developer Program credentials are introduced, the trusted path may add Developer ID signing and notarization. It must preserve the same security, provenance, testing, performance and immutable-release requirements; trusted distribution is an additional packaging property, not a replacement for them.

## 5. Release integrity

Every release should make it possible to identify:

- semantic version and tag;
- exact source commit;
- build number;
- distribution tier;
- relevant third-party adapter provenance where applicable;
- integrity/checksum information exposed by the workflow/release;
- whether notarization is present.

Never infer `released` from `VERSION`, a merged PR, or a green build alone. GitHub Release/tag state is authoritative for publication.

## 6. Rollback / defect handling

Published releases remain immutable. If a release defect is discovered:

1. document/reproduce it;
2. add automated regression coverage where deterministic;
3. fix on a new branch/PR;
4. obtain automated acceptance;
5. merge to `main`;
6. increment the version and publish a new release.
