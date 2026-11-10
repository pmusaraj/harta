# TestFlight distribution

Automatic signing uses Apple Developer team `M4XMDAF939`, configured in `project.yml` so it survives regeneration. The app supports iPhone and iPad on iOS/iPadOS 26 or later.

Install Xcode 26+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). In Xcode → Settings → Accounts, sign into an Apple account with access to this team's certificates/profiles and App Store Connect app. Select the full Xcode installation as your command-line tools in Xcode → Settings → Locations. The team's Apple Developer Program membership and required agreements must be active.

From the repo root, choose an unused build number higher than the last uploaded build:

```sh
scripts/testflight.sh archive 1  # Signed Release archive only
scripts/testflight.sh export 1   # Build and export an IPA locally
scripts/testflight.sh upload 1   # Build and upload to App Store Connect
```

Each command regenerates the project and creates a fresh archive. These are alternatives; you do not need to run all three. Artifacts, export options, and logs go into `.build/testflight/<build-number>/<timestamp>/`. Uploads are eligible for both internal and external testing. Uploading does not submit the app for App Store release or automatically invite testers.

`MARKETING_VERSION` in `project.yml` controls the release version (currently `0.1.0`). The script overrides `CURRENT_PROJECT_VERSION` for that build and disables automatic upload-time renumbering; it does not edit the default build number in the project. For manual Organizer uploads, increment `CURRENT_PROJECT_VERSION` in `project.yml` and run `xcodegen generate` first. The script accepts integer build numbers from 1 through 9999; never reuse an uploaded number.

For App Store Connect API-key authentication, copy `.env.testflight.example` to `.env.testflight` and set `ASC_KEY_PATH`, `ASC_KEY_ID`, and `ASC_ISSUER_ID`, or supply those variables through your environment. Use a team API key with appropriate app and signing access. Keep its `.p8` file outside the repo. The local environment file, signing keys, and build artifacts are ignored by git. Automatic provisioning is enabled for archive and export; Xcode can create/update signing assets when the account has permission. A new machine may still need signing credentials configured in Xcode before archiving succeeds.

The existing portal setup is recorded as iOS app Harta with bundle ID `com.musaraj.harta` and SKU `hartapmusaraj`. Confirm it is accessible under the selected team in App Store Connect before the first upload.

In Xcode, select the Harta scheme, your developer team, and the generic iOS device destination. Choose Product → Archive, then Organizer → Distribute App → App Store Connect → Upload. Do not choose TestFlight Internal Only if this build will be shared with external testers. Xcode manages signing certificates and provisioning with your account.

After processing, open the app's TestFlight tab, answer export-compliance questions, add testing notes, and assign the build to a tester group. Internal testers must be eligible App Store Connect users. For external testers, supply the beta description, feedback email, review contact, and review notes, then submit for TestFlight App Review before inviting testers. No login is required in Harta. Explain that location is used for navigation and background location/audio support active guidance; navigation starts muted and testers can enable voice.

Apple reference: [Upload builds to App Store Connect](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).

Suggested testing notes: Test search, saved places, walking/cycling/driving route previews, location permissions, navigation and rerouting, voice prompts, and locked-screen guidance. End navigation and confirm guidance stops. Internet access is required; offline routing and live traffic are unavailable.

Before broad testing, review the [service boundaries in the development guide](DEVELOPMENT.md#service-boundaries) and provider privacy practices. The app privacy manifest declares UserDefaults access for local app preferences; it does not replace App Store Connect privacy disclosures or a review of third-party SDK manifests. Complete export-compliance answers based on the app and its dependencies.

See [Development](DEVELOPMENT.md) for local builds and tests, or return to [Harta](README.md).

## Release safeguards and prepared beta information

The archive script checks the built app for a nonempty Stadia key and CloudKit sharing support before export/upload. It never prints the key. Distribution explicitly selects the Production iCloud environment. `project.yml` declares `ITSAppUsesNonExemptEncryption = false`: the app uses platform networking/iCloud security and no custom non-exempt encryption. Reassess that declaration if encryption dependencies or functionality change.

Prepared English text for App Store Connect:

- `Configuration/TestFlight/BetaDescription.txt`: Test Information → Beta App Description.
- `Configuration/TestFlight/WhatToTest.txt`: the build's What to Test field.
- `Configuration/TestFlight/ReviewNotes.txt`: Beta App Review → Notes.

These files are local prepared text; Xcode upload does not populate these fields. Feedback email and review contact name/email/phone must be supplied in App Store Connect. For family members who are not App Store Connect team users, use an external testing group and complete Beta App Review before inviting them. Uploading alone does not send invitations.

## CloudKit production preparation

TestFlight uses **Production**; local device builds normally use **Development**. Do not use a development invitation to test a production build. Create a fresh invitation from TestFlight after production setup.

1. Open https://icloud.developer.apple.com/ and select team `M4XMDAF939`, container `iCloud.com.musaraj.harta`.
2. In Development, verify the `FamilyMap` record type has a `places` field of type Asset. If it has not been created yet, use Share my saved places in the locally installed development build while signed into iCloud, or create the record type/field in Console. The app uses direct record-ID fetches, so no custom query indexes are required.
3. Use Deploy Schema Changes to promote the development schema to Production. Deployment promotes schema, not development records. CloudKit's system share records and private owner/participant access handle invitations; do not grant public access to map data.
4. Test two TestFlight installations with separate iCloud accounts before distributing family sharing more broadly.

CloudKit management authorization is separate from Xcode signing. For command-line schema inspection, configure a management token with `xcrun cktool save-token` using a token generated in CloudKit Console; do not commit or paste the token into documentation. Then inspect Production with:

```sh
xcrun cktool export-schema --team-id M4XMDAF939 \
  --container-id iCloud.com.musaraj.harta --environment production \
  --output-file /tmp/harta-production.ckdb
```

Signing/archiving successfully does not establish that the production schema is deployed or that invitations have been tested.

## Latest upload — November 9, 2026

Version **0.1.0 (5)** was successfully archived and uploaded using the signed-in Xcode account. Apple reported that the uploaded package was processing; TestFlight availability and group assignment have not been confirmed. The release archive contains the Stadia key, family sharing, and long-press saved-place renaming.

Artifacts: `.build/testflight/5/20261110T000913Z-292/`. Upload completed with a non-blocking warning that the vendor MapLibre framework's matching dSYM is absent; this limits crash symbolication within MapLibre. The upload itself succeeded.

Still pending: verify/deploy the CloudKit production schema, populate the prepared beta metadata and contact fields in App Store Connect, assign build 5 to the intended group, and complete Beta App Review for external family testers. No tester invitations have been sent. CloudKit management access was checked with `cktool get-teams`, which reported no configured management token. App Store Connect metadata API credentials are not configured in this workspace; Xcode signing/upload access does not supply those API credentials.
