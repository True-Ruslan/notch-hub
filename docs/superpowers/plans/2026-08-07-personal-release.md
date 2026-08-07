# Personal Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish immutable personal-use `v0.1.0` GitHub Releases from protected `main` without paid Apple credentials while preserving App Sandbox, Hardened Runtime, security gates, provenance, checksums, and explicit Gatekeeper limitations.

**Architecture:** Keep the current Developer ID/notarization workflow as an optional future trusted tier and add a separate personal-release workflow that has no Apple secrets or release environment dependency. Put release-state validation and metadata generation in small Python-stdlib scripts with deterministic unit tests; keep GitHub Actions as orchestration only.

**Tech Stack:** Swift 6, Swift Package Manager, AppKit/SwiftUI, Bash, Python 3 standard library, GitHub Actions, GitHub CLI, macOS `codesign`, `hdiutil`, `shasum`.

## Global Constraints

- Target repository: `True-Ruslan/notch-hub`.
- Current personal version: `0.1.0`; tag format is exactly `v<SemVer>`.
- Personal Release is ad-hoc signed, App Sandbox enabled, Hardened Runtime enabled, and explicitly not Developer ID signed/notarized.
- Never disable Gatekeeper, remove quarantine recursively, install a custom trusted root, or broaden entitlements to suppress first-launch warnings.
- Published version/tag is immutable; an existing tag or GitHub Release must make the workflow fail before publication.
- Release source must be exactly current protected `main`.
- Runtime application remains local-first with zero third-party Swift runtime dependencies and no new runtime network/process/dynamic-loading capability.
- External GitHub Actions remain pinned to immutable full 40-character SHAs.
- Trusted Developer ID/notarized distribution remains available as a separate future tier and may not overwrite a personal release tag/version.

---

## File Structure

- Create `scripts/release_policy.py` — pure release-policy helpers: SemVer parsing, tag derivation, immutable release checks, build-metadata construction, personal-release note validation.
- Create `scripts/test_release_policy.py` — Python `unittest` coverage for policy helpers and malformed inputs.
- Create `docs/releases/v0.1.0.md` — human-maintained release notes whose first section states personal/ad-hoc trust limitations.
- Create `.github/workflows/personal-release.yml` — manual personal-release publisher from `main` only.
- Rename `.github/workflows/release.yml` to `.github/workflows/trusted-release.yml` — keep paid Developer ID/notarization workflow separate and clearly named; do not change its security gates except source/release-name collision policy needed by immutable tiers.
- Modify `.github/workflows/ci.yml` — run release-policy unit tests and static workflow validation in normal PR CI.
- Modify `scripts/security-audit.sh` — treat both release workflows as supply-chain surfaces and prohibit silent weakening of personal-release trust labeling/immutability invariants.
- Modify `SECURITY.md`, `docs/ARCHITECTURE.md`, `docs/RELEASING.md`, `docs/TESTING.md`, `docs/ROADMAP.md`, `docs/PROJECT_STATE.md`, `README.md`, `CHANGELOG.md` — make Personal Release the current default and Trusted Release optional.

---

### Task 1: Deterministic release policy library

**Files:**
- Create: `scripts/release_policy.py`
- Create: `scripts/test_release_policy.py`

**Interfaces:**
- Produces: `parse_semver(value: str) -> tuple[int, int, int]`
- Produces: `release_tag(version: str) -> str`
- Produces: `validate_personal_release_notes(text: str, version: str) -> None`
- Produces: `build_metadata(version: str, build_number: str, source_sha: str, runner_os: str, xcode_version: str, swift_version: str, dmg_sha256: str, dmg_size_bytes: int, app_size_bytes: int, executable_size_bytes: int) -> dict[str, object]`
- Produces CLI subcommands: `validate-notes`, `metadata`.

- [ ] **Step 1: Write RED unit tests for SemVer/tag validation**

Create `scripts/test_release_policy.py` with tests equivalent to:

```python
import unittest
from release_policy import parse_semver, release_tag

class ReleasePolicyTests(unittest.TestCase):
    def test_release_tag_accepts_strict_three_component_semver(self):
        self.assertEqual((0, 1, 0), parse_semver("0.1.0"))
        self.assertEqual("v0.1.0", release_tag("0.1.0"))

    def test_release_tag_rejects_non_release_versions(self):
        for value in ("0.1", "v0.1.0", "0.1.0-beta", "01.1.0", " 0.1.0 "):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    release_tag(value)
```

- [ ] **Step 2: Run RED test**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: FAIL because `release_policy` does not exist.

- [ ] **Step 3: Implement strict SemVer/tag helpers**

Implement with only Python standard library and a full-match regex equivalent to `0|[1-9][0-9]*` for each numeric component. Do not `.strip()` input; repository `VERSION` reading is responsible for removing the trailing newline.

- [ ] **Step 4: Run GREEN test**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: PASS for SemVer/tag tests.

- [ ] **Step 5: Write RED tests for release-note trust labeling**

Add tests that require the first Markdown heading after the title to be exactly `## Personal build — not notarized`, require the version in the title, require the phrases `ad-hoc signed` and `Open Anyway`, and reject text containing instructions to disable Gatekeeper or run `xattr -dr com.apple.quarantine`.

- [ ] **Step 6: Run RED note-policy tests**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: FAIL because `validate_personal_release_notes` does not exist.

- [ ] **Step 7: Implement note-policy validation**

Implement `validate_personal_release_notes(text, version)` so failures raise `ValueError` with a precise invariant name. Do not silently normalize missing sections.

- [ ] **Step 8: Run GREEN note-policy tests**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: PASS.

- [ ] **Step 9: Write RED tests for build metadata**

Assert exact schema and types:

```python
expected_keys = {
    "schemaVersion", "version", "tag", "buildNumber", "sourceCommit",
    "runnerOS", "xcodeVersion", "swiftVersion", "dmgSHA256",
    "dmgSizeBytes", "appSizeBytes", "executableSizeBytes", "distributionTier",
    "appleTrusted", "notarized"
}
self.assertEqual(expected_keys, set(metadata))
self.assertEqual("personal", metadata["distributionTier"])
self.assertIs(False, metadata["appleTrusted"])
self.assertIs(False, metadata["notarized"])
```

Also reject non-64-hex SHA-256, non-40-hex source SHA, non-positive build numbers, and negative sizes.

- [ ] **Step 10: Implement metadata builder + CLI**

`metadata` CLI writes deterministic UTF-8 JSON using `sort_keys=True`, `indent=2`, and a final newline. All fields are supplied explicitly as CLI arguments; no ambient secret/environment scanning.

- [ ] **Step 11: Run full policy tests**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: all PASS.

- [ ] **Step 12: Commit Task 1**

Commit message: `test: define personal release policy`

---

### Task 2: Versioned personal release notes

**Files:**
- Create: `docs/releases/v0.1.0.md`
- Test: `scripts/test_release_policy.py`

**Interfaces:**
- Consumes: `validate_personal_release_notes(text, version)`.
- Produces: canonical notes file consumed verbatim by Personal Release workflow.

- [ ] **Step 1: Add an integration-style policy test that loads `../docs/releases/v0.1.0.md`**

Test must read repository `VERSION`, derive `docs/releases/v<version>.md`, and validate it. Expected initial failure: file missing.

- [ ] **Step 2: Run RED test**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: FAIL with missing release-notes file.

- [ ] **Step 3: Create `docs/releases/v0.1.0.md`**

Required opening structure:

```markdown
# NotchHub v0.1.0 — Personal build

## Personal build — not notarized

This release is for personal use. It is ad-hoc signed with App Sandbox and Hardened Runtime enabled, but it is not Developer ID signed or Apple-notarized. macOS may require Finder **Open** or **System Settings → Privacy & Security → Open Anyway** on first launch. Do not disable Gatekeeper.
```

Then summarize M0 foundation, security posture, macOS 26.6 hardware acceptance, and known limitations. Do not claim Apple trust.

- [ ] **Step 4: Run GREEN test**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: all PASS.

- [ ] **Step 5: Commit Task 2**

Commit message: `docs: prepare v0.1.0 personal release notes`

---

### Task 3: Personal Release workflow with fail-closed immutability

**Files:**
- Create: `.github/workflows/personal-release.yml`
- Modify: `.github/workflows/ci.yml`
- Test: `scripts/test_release_policy.py`

**Interfaces:**
- Consumes: `VERSION`, `docs/releases/v<version>.md`, `scripts/release_policy.py`, `scripts/security-audit.sh`, `scripts/build-dmg.sh`.
- Produces: immutable GitHub Release assets `NotchHub.dmg`, `NotchHub.dmg.sha256`, `build-metadata.json`.

- [ ] **Step 1: Add RED static workflow tests**

Extend `scripts/test_release_policy.py` to load `.github/workflows/personal-release.yml` and assert all of these strings/invariants exist:

```text
workflow_dispatch:
permissions:\n  contents: write
persist-credentials: false
fetch-depth: 0
scripts/security-audit.sh
swift build -Xswiftc -warnings-as-errors
swift test --parallel --enable-code-coverage
codesign --verify --deep --strict
flags=.*runtime
com.apple.security.app-sandbox
hdiutil verify
shasum -a 256
release_policy.py metadata
gh release view
git rev-parse -q --verify refs/tags/
gh release create
--notes-file
```

Also assert it does **not** contain `notarytool`, `Developer ID Application`, Apple secret names, `--clobber`, or `xattr`.

- [ ] **Step 2: Run RED workflow-policy tests**

Run: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: FAIL because workflow does not exist.

- [ ] **Step 3: Create Personal Release workflow**

Implement one manual `workflow_dispatch` job on `macos-26`, no `environment: release`, with these ordered gates:

1. checkout full history, no persisted credentials;
2. require `GITHUB_REF_NAME == main` and `GITHUB_SHA == git rev-parse refs/remotes/origin/main`;
3. derive version/tag from `VERSION` using `scripts/release_policy.py`;
4. validate versioned notes;
5. fail if `refs/tags/$RELEASE_TAG` exists locally/remotely or `gh release view` succeeds;
6. run package/format/plist/shell/security/build/test quality baseline;
7. build ad-hoc release DMG with `BUILD_NUMBER=${{ github.run_number }}`;
8. verify bundle identifier/version/build number, strict code signature, Hardened Runtime, exact App Sandbox entitlement, system-only dylibs, and `hdiutil verify`;
9. calculate DMG SHA-256 and byte sizes for DMG/app/executable;
10. generate `build-metadata.json` through tested script;
11. re-run the tag/release nonexistence check immediately before publish to reduce race window;
12. `gh release create "$RELEASE_TAG" ... --target "$GITHUB_SHA" --title "NotchHub $RELEASE_TAG — Personal build" --notes-file "$NOTES"`.

Do not upload/replace assets on an existing release.

- [ ] **Step 4: Add policy tests to normal CI**

In `.github/workflows/ci.yml`, after package validation, add:

```bash
(cd scripts && python3 -m unittest -v test_release_policy.py)
```

Normal PR CI must prove release orchestration policy before merge.

- [ ] **Step 5: Run GREEN policy/static tests**

Run locally/CI equivalent: `cd scripts && python3 -m unittest -v test_release_policy.py`

Expected: PASS.

- [ ] **Step 6: Run full project verification**

Run:

```bash
swift format lint --recursive --strict --configuration .swift-format Sources Tests Package.swift
./scripts/security-audit.sh
swift build -Xswiftc -warnings-as-errors
swift test --parallel --enable-code-coverage
./scripts/build-dmg.sh
```

Expected: PASS.

- [ ] **Step 7: Commit Task 3**

Commit message: `feat: add immutable personal release workflow`

---

### Task 4: Separate future Trusted Release tier

**Files:**
- Create: `.github/workflows/trusted-release.yml` from current trusted workflow
- Delete: `.github/workflows/release.yml`
- Modify: `scripts/test_release_policy.py`

**Interfaces:**
- Produces: clearly named future workflow only; no tag collision with existing Personal Release versions.

- [ ] **Step 1: Add RED static test for tier separation**

Assert `trusted-release.yml` exists, has `name: Trusted Release`, contains `notarytool`, `Developer ID Application`, `environment: release`, and Apple secret names; assert `release.yml` no longer exists after implementation. Assert trusted workflow fails if the matching tag/release already exists rather than overwriting a Personal Release.

- [ ] **Step 2: Run RED test**

Expected: FAIL because files are not yet separated.

- [ ] **Step 3: Rename and harden trusted workflow**

Copy current workflow to `trusted-release.yml`, rename display/job names to trusted terminology, remove any `gh release upload --clobber` path, and require no existing tag/release before publication. Keep Developer ID/notary/stapler/Gatekeeper verification unchanged.

- [ ] **Step 4: Delete old ambiguous workflow**

Delete `.github/workflows/release.yml`.

- [ ] **Step 5: Run GREEN static tests + security audit**

Run:

```bash
(cd scripts && python3 -m unittest -v test_release_policy.py)
./scripts/security-audit.sh
```

Expected: PASS.

- [ ] **Step 6: Commit Task 4**

Commit message: `chore: separate trusted release tier`

---

### Task 5: Security baseline recognizes personal distribution

**Files:**
- Modify: `scripts/security-audit.sh`
- Modify: `SECURITY.md`
- Test: `scripts/test_release_policy.py`

**Interfaces:**
- Consumes both release workflows.
- Produces fail-closed repository invariants without pretending ad-hoc signing is Apple trust.

- [ ] **Step 1: Add RED tests for forbidden personal-release weakening**

Use temporary workflow text with helper-level tests to prove policy rejects `--clobber`, `notarytool` in Personal Release, Apple signing secret names in Personal Release, and unsafe Gatekeeper-bypass instructions in versioned release notes.

- [ ] **Step 2: Extend executable security audit**

Add repository checks that:

- `personal-release.yml` exists and contains no Apple-secret/notarization/Developer ID patterns;
- no release workflow uses `--clobber`;
- every external Action remains full-SHA pinned;
- personal release notes validate through `release_policy.py`;
- the app entitlements remain exactly sandbox-only.

- [ ] **Step 3: Update `SECURITY.md` invariant 12**

Replace “all user-facing GitHub Releases are notarized” with two explicit tiers. State Personal Release accepted risk: ad-hoc signing has no Apple identity/notarization trust, but Sandbox/Hardened Runtime/checksum/provenance remain mandatory. Trusted Release retains Developer ID/notarization requirements.

- [ ] **Step 4: Run security regression suite**

Run:

```bash
(cd scripts && python3 -m unittest -v test_release_policy.py)
./scripts/security-audit.sh
```

Expected: PASS.

- [ ] **Step 5: Commit Task 5**

Commit message: `security: define personal release trust boundary`

---

### Task 6: Source-of-truth documentation and release state

**Files:**
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/RELEASING.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Produces a new-chat-restorable description of current release policy and exact next step.

- [ ] **Step 1: Update distribution architecture**

Document three artifact meanings: CI test artifact, Personal Release, future Trusted Release. Explicitly state that Personal Release is current default and Trusted Release requires paid Apple membership.

- [ ] **Step 2: Update release instructions**

`docs/RELEASING.md` must give exact safe first-launch path for Personal Release: download from GitHub Release, verify checksum, drag app to Applications, use Finder **Open**; if macOS blocks it, use System Settings → Privacy & Security → Open Anyway. Do not document shell-based quarantine bypasses.

- [ ] **Step 3: Update testing/roadmap/state**

Add `NH-PERSONAL-RELEASE-001`: downloaded GitHub Release checksum matches, app opens after only standard macOS user approval, M0 behavior remains correct. Mark Apple Developer Program as deferred/optional rather than blocker. Set Performance Foundation as next milestone after personal v0.1.0 publication.

- [ ] **Step 4: Finalize changelog for 0.1.0 release candidate**

Before publication, move the accepted M0 entries under `## [0.1.0] - 2026-08-07`, recreate an empty `## [Unreleased]`, and add correct compare links. Do this only in the release-preparation PR so the versioned notes and changelog agree.

- [ ] **Step 5: Run full verification**

Run all policy tests, security audit, Swift build/tests, and CI.

- [ ] **Step 6: Commit Task 6**

Commit message: `docs: make personal releases the default distribution`

---

### Task 7: PR acceptance and publish v0.1.0

**Files:**
- No production source changes expected.
- Update `docs/PROJECT_STATE.md` only if final CI/release results change state.

**Interfaces:**
- Consumes accepted PR + protected `main`.
- Produces GitHub Release `v0.1.0` and post-download acceptance result.

- [ ] **Step 1: Open PR A from implementation branch to `main`**

PR must enumerate release trust differences, TDD/static-test evidence, unchanged app entitlements, and manual post-download check.

- [ ] **Step 2: Require protected CI green**

Verify macOS 26 compatibility, policy tests, security audit, Swift tests, package/signature/Sandbox/Hardened Runtime/DMG gates all pass.

- [ ] **Step 3: Squash-merge PR A**

Only after CI is green and no unresolved review threads remain.

- [ ] **Step 4: Run `Personal Release` workflow manually on `main`**

Expected: creates `v0.1.0`, `NotchHub v0.1.0 — Personal build`, DMG, checksum, build metadata. Any existing tag/release must make the job fail rather than mutate it.

- [ ] **Step 5: Perform `NH-PERSONAL-RELEASE-001` on target macOS 26.6**

Manual minimum:

1. download DMG and `.sha256` from GitHub Release;
2. verify `shasum -a 256 NotchHub.dmg` matches published checksum;
3. open/install using normal Finder flow;
4. if blocked, use standard Privacy & Security → Open Anyway only;
5. verify `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` remain PASS.

- [ ] **Step 6: Record release acceptance in `PROJECT_STATE.md` via a small follow-up PR if needed**

Do not rewrite the immutable `v0.1.0` artifact/tag.
