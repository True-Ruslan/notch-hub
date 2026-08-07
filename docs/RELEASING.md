# Releasing NotchHub

Stable releases are distributed through GitHub Releases. Chat attachments and raw CI artifacts are for development/testing only.

## Release trust model

A stable release must pass all of the following:

1. protected-branch CI, including macOS 26 compatibility;
2. required real-hardware acceptance recorded in `docs/PROJECT_STATE.md`;
3. Developer ID Application signing;
4. Hardened Runtime with no dangerous exception entitlements;
5. App Sandbox with the reviewed minimal entitlement set;
6. Apple notarization via `notarytool`;
7. notarization ticket stapled to the DMG and validated;
8. Gatekeeper assessment of the app from the mounted DMG;
9. SHA-256 checksum published beside the DMG.

Apple Developer Program membership is required to obtain a Developer ID certificate. Apple notarization requires Developer ID signing and Hardened Runtime.

## One-time Apple setup

Do not send certificates, private keys, passwords, or App Store Connect keys through chat, issues, commits, or pull requests.

1. Join the Apple Developer Program if the account is not already enrolled.
2. Create a **Developer ID Application** certificate in the Apple Developer account/Xcode.
3. Export the certificate plus its private key from Keychain Access as a password-protected `.p12`.
4. Create an App Store Connect API key that can use the Apple notarization service and download the `.p8` key once.

## GitHub release environment

Create an environment named `release` in repository settings. Store these as **environment secrets**:

- `APPLE_DEVELOPER_ID_P12_BASE64` — base64 text of the exported `.p12` file;
- `APPLE_DEVELOPER_ID_P12_PASSWORD` — password used when exporting the `.p12`;
- `APPLE_NOTARY_KEY_P8` — complete contents of the App Store Connect `.p8` private key;
- `APPLE_NOTARY_KEY_ID` — App Store Connect key ID;
- `APPLE_NOTARY_ISSUER_ID` — App Store Connect issuer ID.

On macOS, create the base64 value locally without uploading the certificate anywhere else:

```bash
base64 -i DeveloperID.p12 | pbcopy
```

Paste the result directly into the GitHub environment secret.

For additional release-chain protection, configure the `release` environment to require manual approval before a job can access its secrets if the GitHub plan/settings offer that control.

## Publishing

After the accepted release commit is on `main` and `VERSION`/`CHANGELOG.md` are correct:

1. Open **Actions → Release → Run workflow**.
2. Run it against `main`.
3. The workflow derives the tag from `VERSION`, signs the app and DMG, notarizes/staples it, verifies Gatekeeper, creates a SHA-256 checksum, creates the `v<version>` tag if needed, and publishes the GitHub Release.

A tag push matching `v*` also invokes the same workflow, but manual dispatch is the preferred personal-project flow because all signing/notarization gates are visible in one place.

## Failed release

A failed signing, notarization, stapling, Gatekeeper, checksum, or security check must fail closed: do not publish or manually upload the rejected artifact as a stable release. Fix the root cause in a PR and run the release workflow again from the corrected `main` commit.

## Test builds

PR CI continues to produce an ad-hoc signed `NotchHub.dmg`. It enables Hardened Runtime and App Sandbox so security-sensitive packaging stays exercised, but it is **not** Developer ID signed/notarized and therefore may trigger Gatekeeper warnings. This distinction is intentional.
