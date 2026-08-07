# Releasing NotchHub

Versioned builds are distributed through GitHub Releases. Chat attachments and raw CI artifacts are development/testing only.

NotchHub currently supports a **Personal Release** tier for private use without paid Apple Developer membership. A separate **Trusted Release** tier remains available for the future if Developer ID/notarization becomes worthwhile.

## 1. Personal Release — current default

Workflow: **Actions → Personal Release → Run workflow**, branch `main`.

Personal Release intentionally uses an ad-hoc application signature. It is **not** Developer ID signed and **not** Apple-notarized. App Sandbox and Hardened Runtime remain enabled and verified.

Before publication the workflow requires:

1. selected ref is exactly current protected `main`;
2. strict `VERSION`/SemVer and versioned release-notes policy;
3. target tag/release does not already exist;
4. Swift package/format/security policy checks;
5. warnings-as-errors build;
6. complete Swift tests with coverage instrumentation;
7. ad-hoc release app + DMG build;
8. bundle identifier/version/build checks;
9. strict code-signature verification and explicit `Signature=adhoc` check;
10. Hardened Runtime verification;
11. exact effective App Sandbox entitlement verification;
12. system-library-only linkage at the current milestone;
13. `hdiutil verify` on the DMG;
14. SHA-256 generation;
15. machine-readable provenance/build metadata;
16. a second tag/release absence check immediately before publication.

Published assets:

- `NotchHub.dmg`
- `NotchHub.dmg.sha256`
- `build-metadata.json`

The title is `NotchHub v<version> — Personal build`, and the first release-note section must be `Personal build — not notarized`.

### Immutability

A published tag/version is immutable. The workflow never uses `gh release upload --clobber`. If a build is wrong, fix it in a PR, increment `VERSION`, prepare new versioned release notes, and publish a new version.

The workflow is manual-only (`workflow_dispatch`). A push/tag does not automatically publish a Personal Release.

## Safe first launch of a Personal Release

The absence of Developer ID/notarization means macOS may block or warn on the first launch of a downloaded copy. This is expected and is not treated as a product/security failure for the personal tier.

Safe flow:

1. Download `NotchHub.dmg` and `NotchHub.dmg.sha256` from the GitHub Release.
2. Optionally verify the checksum in Terminal:

```bash
shasum -a 256 NotchHub.dmg
cat NotchHub.dmg.sha256
```

The hashes must match exactly.

3. Open the DMG and move `NotchHub.app` to Applications.
4. In Finder, use **Open** on `NotchHub.app`.
5. If macOS still blocks it, open **System Settings → Privacy & Security → Open Anyway**, then confirm the standard macOS prompt.

Do **not** disable Gatekeeper, run `spctl --master-disable`, recursively remove quarantine attributes, or install a custom trusted root merely to suppress this warning.

## Personal Release acceptance

Use `NH-PERSONAL-RELEASE-001` from `docs/TESTING.md`. It verifies the normally downloaded GitHub Release, checksum, standard macOS approval path, and accepted notch/hover behavior on the target MacBook/macOS 26.6.

A failed post-download acceptance does not permit replacing the existing release artifact. Fix and increment the version.

## 2. Trusted Release — optional future tier

Workflow: **Actions → Trusted Release → Run workflow**.

Do not configure or run this workflow until Apple Developer Program membership is intentionally adopted. It remains isolated from Personal Release.

Trusted Release additionally requires:

- Developer ID Application certificate/private key;
- Apple notarization credentials;
- GitHub environment `release`;
- Developer ID app + DMG signing;
- Hardened Runtime and Sandbox verification;
- `notarytool` acceptance;
- stapling/validation;
- Gatekeeper assessment showing `source=Notarized Developer ID`.

It also refuses to publish if the same tag/release already exists. Therefore a Personal Release version can never later be silently replaced by a trusted artifact; a new trusted build needs a new version.

### Future Apple setup

If this tier becomes useful, never send certificates/private keys/passwords through chat, issues, commits, or PRs. Store only in the GitHub `release` environment:

- `APPLE_DEVELOPER_ID_P12_BASE64`
- `APPLE_DEVELOPER_ID_P12_PASSWORD`
- `APPLE_NOTARY_KEY_P8`
- `APPLE_NOTARY_KEY_ID`
- `APPLE_NOTARY_ISSUER_ID`

The annual Apple Developer Program dependency is intentionally deferred for the current personal-use project.

## CI test artifacts

Normal PR/main CI still produces `NotchHub-dmg`. It is ad-hoc signed with Sandbox/Hardened Runtime and exists only for development/hardware acceptance. It is not a versioned GitHub Release and has no release immutability/provenance claim beyond the Actions run that produced it.

## Failed release workflow

Any failed policy, test, security, packaging, signature, entitlement, provenance, checksum, notarization (trusted tier), or publication precondition must fail closed. Fix the root cause in a PR. Never bypass a failed gate with a manually uploaded replacement artifact under the same version.
