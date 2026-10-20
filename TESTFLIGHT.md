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
