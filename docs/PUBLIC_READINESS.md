# Public repository readiness

Last reviewed: 2026-08-07

## Goal

Make the NotchHub source repository safe to expose publicly without broadening application permissions, weakening release integrity, or giving untrusted pull requests access to privileged GitHub Actions capabilities.

This document records the pre-publication audit. It is not a claim that GitHub account-level settings can never change; repository settings must be rechecked immediately after the visibility transition.

## Repository-history audit

The repository has a short, reviewable `main` history:

1. `6e04fa4226e60507e399f1f5b1a3cedce4678182` — initial commit;
2. `eb7bcfda3c6938d5bc3a13a6ccbfa85e062e39cb` — M0 foundation / PR #1;
3. `04487ae9149eb9850d66aae4952e4cfedfcd55da` — release/performance design / PR #2;
4. `8e913dcddfdec7d9aa920df8c37afb23b8c40884` — Personal Release / PR #3;
5. `8fb5a66ffcfefabfa9174ebc42ebeb92a4debafa` — M1 interaction specification / PR #4;
6. `a056aa74bad5d8e193eb4c76a76e6c910344bd09` — P0 Performance Foundation / PR #5.

Before preparing public visibility, the initial commit and the complete accessible PR #1–#5 diffs/discussions were reviewed for credential/private-key material and unintended private content.

Result: **no secret value, API token, password, certificate/private key, or signing credential was found.** Historical workflow text contains only GitHub Secret *names* such as Apple signing/notarization variable names; secret values are not present in repository history.

No repository-history rewrite is required by the reviewed evidence.

## Data intentionally safe to publish

The repository intentionally contains non-secret engineering provenance, including:

- Git commit SHAs and release checksums;
- generic target model identifier `Mac16,8` used for reproducible performance evidence;
- macOS/Xcode/Swift versions;
- aggregate process CPU/RSS/thread measurements;
- executable/app/DMG byte sizes;
- GitHub repository/user name and public product documentation.

The performance harness explicitly excludes usernames, home paths, pointer history, clipboard/snippet content, user files, calendar/media content, and hardware serial numbers from the canonical baseline.

## Public pull-request CI boundary

Untrusted fork code may execute only through ordinary `.github/workflows/ci.yml` pull-request CI.

Executable policy requires that CI:

- uses the ordinary `pull_request` event;
- has explicit `contents: read` permission;
- never uses `pull_request_target` or `workflow_run` as an untrusted-code execution bridge;
- never references repository `secrets.*`;
- never runs untrusted PR code on `self-hosted` runners;
- never grants a `write` permission, `permissions: write-all`, or OIDC `id-token: write` authority;
- keeps `actions/checkout` credentials disabled with `persist-credentials: false`;
- keeps third-party Actions pinned to immutable full commit SHAs.

These invariants are covered by `scripts/test_release_policy.py`, `scripts/release_policy.py validate-public-ci`, and `scripts/security-audit.sh`.

### RED → GREEN evidence

The public-CI boundary was introduced test-first. RED CI #123 failed exactly while importing the deliberately missing `validate_public_ci_workflow` helper:

`ImportError: cannot import name 'validate_public_ci_workflow' from 'release_policy'`

The validator, CLI command, and executable security-audit integration were implemented only after that RED evidence. Final GREEN evidence is required on the exact PR head before merge; transient GitHub-hosted runner failures that never reach checkout/test steps are treated as infrastructure failures rather than application evidence.

## Release workflow boundary

Publication remains separate from fork PR execution:

- Personal Release is manual `workflow_dispatch`, exact-`main` only, and contains no custom repository/Apple secrets;
- Trusted Release is manual `workflow_dispatch`, exact-`main` only, behind the `release` environment, and is the only workflow allowed to reference Apple signing/notarization secrets;
- neither release path may overwrite an existing tag/release;
- public PR CI cannot invoke either release workflow with write authority.

## Runtime/security boundary

Changing repository visibility changes source availability, not application authority. The public-readiness change does not modify `Sources/`, entitlements, runtime networking, telemetry, input capture, persistence, subprocess behavior, signing requirements, or performance budgets.

## License

The repository is licensed under the MIT License in root `LICENSE`.

## Required post-visibility verification

Immediately after changing GitHub visibility to Public, verify the actual repository settings rather than assuming private-repository settings were preserved:

1. visibility reports `public`;
2. `main` still has the intended protection/ruleset and squash-only integration policy;
3. required CI checks still apply before merge;
4. Actions default workflow permissions remain least privilege;
5. fork pull-request workflows do not receive write tokens or repository secrets;
6. release environments/secrets remain isolated from pull-request CI;
7. `v0.1.0` Release assets, checksum, and provenance remain intact;
8. a normal public-source CI run remains green.

If any of these checks cannot be proven, public-readiness remains incomplete until the repository setting is corrected.
