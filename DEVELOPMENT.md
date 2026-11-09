# Development

Harta (`com.musaraj.harta`) is a native SwiftUI iOS prototype with MapLibre Native. iOS 26+, Xcode 26+.

Open `Harta.xcodeproj`, select the **Harta** scheme and an iOS 26 simulator, then Run. Swift Package Manager downloads the pinned MapLibre 6.31.0 and Ferrostar 0.57.0 SDKs. Search and routing require a Stadia Maps API key. Copy `Configuration/Local.xcconfig.example` to `Configuration/Local.xcconfig` and replace the placeholder key. This local file is ignored by Git and is included by both Debug and Release builds. The key is embedded in the built app; use a dedicated prototype key and monitor usage in the Stadia dashboard. Missing keys produce an explicit error; there is no public-demo fallback.

For a physical device, select your development team in Signing & Capabilities. The bundle identifier is `com.musaraj.harta`. The app includes the selected Route H icon (concept 3B).

## Build and test

`project.yml` is the project source of truth. After adding files, regenerate the checked-in Xcode project using [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
xcodebuild -project Harta.xcodeproj -scheme Harta \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Run unit and UI tests with Product → Test in Xcode on an iOS 26 simulator. The live routing UI smoke test is opt-in: pass `RUN_LIVE_ROUTING_TESTS=1` to xcodebuild, grant simulator location permission, and set its location to `43.6426,-79.3871` (near the Toronto default destination). It calls Stadia using the configured key and consumes credits; normal tests do not.

## Map layers

All six overlays use the existing OpenFreeMap tiles, with no extra API or credentials. Colored 22-point circular place badges with white symbols and borders appear from zoom 14, with generous tap targets. Cycling highlights appear from zoom 12 as green dashed lines. Essentials distinguishes groceries (orange basket), corner stores (blue storefront), pharmacies (green medical case), and ATMs (teal banknote). Transit uses blue bus symbols and purple metro, rail, tram, and ferry symbols. Metro/subway entrances use an M symbol; generic railway stations remain rail markers when tiles do not specify the mode. Cycling highlights mapped cycleways and paths tagged for designated/official bicycle use; it is not a complete bike-lane network or a change to route planning.

Coverage follows OpenStreetMap/OpenMapTiles and varies by region. These layers do not provide live charger or parking availability, transit departures, opening hours, or access guarantees. Existing base-style labels remain independent of the optional overlays. The generator in `scripts/map-styles/overlays.py` defines filters and appearance for all eight bundled styles.

## Service boundaries

MapLibre renders OpenFreeMap tiles. Stadia Maps supplies search and Valhalla routes. Typed autocomplete uses `/geocoding/v2/autocomplete` after three characters and a 400 ms pause. Suggestions have no coordinates: selecting one calls `/geocoding/v2/place_details` for that GID only. Explicit Return and voice searches use `/geocoding/v2/search` for complete input. Search responses are cached in memory for at most five minutes (30 entries); editing, dismissing, starting voice, and backgrounding cancel pending work. Saved matches remain available when online requests fail.

Free-plan budgeting: 200,000 credits/month shared by the account, noncommercial use only, no overage. Autocomplete v2 costs 1 credit/request; details, submitted search, and standard routing cost 20 each. Five autocomplete requests + selected-place details + route preview + navigation start cost 65 credits, approximately 3,076 trips/month before reroutes or other requests. Preview and navigation still fetch separate route formats; do not assume one routing call per trip. Reroutes are limited by Ferrostar to at least 15 seconds and 15 metres of movement. No traffic profiles, background prefetch, or automatic paid fallback are enabled. HTTP 429 is surfaced without search retries. Account-wide quota enforcement remains with Stadia. Pricing: https://stadiamaps.com/pricing/.

Search sends partial/submitted text, selected GIDs, and a fresh location bias to Stadia Maps, falling back visibly to map center. Named localities omit coordinate bias. Routing sends origin/destination coordinates and mode; rerouting sends the updated position. OpenFreeMap receives tile requests. Providers receive the device IP address. Saved places remain local unless family sharing is enabled; shared places are uploaded to CloudKit. Recent selections remain local. Online services require connectivity.

Endpoint configuration is in `AppConfiguration.swift`. Regenerate map styles with `python3 scripts/map-styles/generate.py`.

The map requests location on launch, centers on the first fresh fix, and keeps its location dot updated while active. Browsing uses best accuracy with a five-meter distance filter and resumes updates when the app returns to the foreground. Montreal is the fallback while locating or if permission is denied. Panning or choosing a destination cancels automatic recentering; the location button explicitly recenters.

Routing references: [Valhalla API](https://valhalla.github.io/valhalla/api/), [Stadia routing](https://docs.stadiamaps.com/routing/standard-routing/).

## Project notes

- [TestFlight distribution](TESTFLIGHT.md): signing, uploads, and tester setup.
- [PLAN.md](PLAN.md): scope and milestones.
- [Harta](README.md): app overview.


## Voice search

SearchPanel owns a cancellable VoiceCommandModel. AppleSpeechTranscriber captures
with AVAudioEngine, converts buffers for SpeechAnalyzer, downloads assets with
progress, and uses SpeechTranscriber or the on-device DictationTranscriber fallback.
Audio stays in memory. The UI never binds a transcript to the search text field.
AppleVoiceCommandExtractor uses guided Foundation Models output when available;
BasicVoiceCommandParser handles explicit English commands without Apple Intelligence.
SavedPlaceResolver handles direct aliases and exact named destinations. SearchModel
merges other saved matches with Stadia results using PlaceSearchRanking: normalized
name tokens, conservative one-edit typos, sport/category icons, saved status, and
distance. Saved results appear before the network completes and survive failures.
Duplicate IDs or matching names within 50 metres collapse to the saved record.
Explicit named localities filter saved addresses/names and omit GPS bias in Stadia.
PlaceSearchRequest separates current location, map area, and named locality.
Stadia requests up to eight results with focus.point coordinates when biased.
The existing model only extracts voice intent; model-assisted retrieval/ranking is
deferred to stage two. Voice
route requests enter the existing DirectionsView and retain Start navigation.
The microphone is only offered in search panels; active navigation covers those
panels, so voice capture does not run over navigation guidance. Backgrounding,
dismissal, audio interruption, route changes, and typed edits cancel capture.

Unit tests use injectable speech, extraction, and search services; a UI test checks
microphone denial and typed-search recovery. Audio tap callbacks are created outside
the main actor and tested on a background task. A physical iPhone 17 Pro Max smoke
test verified microphone start/stop without a crash on October 20, 2026; this does
not establish recognition accuracy or extraction quality. The physical microphone
UI test requires supported speech assets and microphone permission already granted. Physical-device release checks remain:
first-time downloads/cancellation, Apple Intelligence disabled/not-ready, locale
coverage, real microphone/silence behavior, Bluetooth route changes, phone-call
interruptions, multilingual place names, latency, VoiceOver, and battery use.

## Saved-place symbol search

The icon picker searches bundled SF Symbols names and keywords, filtering availability through the public `UIImage(systemName:)` initializer on a background actor. Common place icons stay first; typing an exact symbol name also supports newer OS symbols beyond the bundled catalog. Artwork is supplied by the OS, not bundled. The current metadata comes from SF Symbols 7.2 (9,184 names, including variants); regenerate with `python3 scripts/symbols/generate.py` after updating Apple's SF Symbols app.

Legacy saved icon identifiers (such as `home` and `tennis`) remain unchanged. Custom selections store `symbol:<system-name>` in the existing optional `savedIcon` field. Unavailable symbols fall back to the place's detected icon or bookmark without dropping the stored value. Icons continue to render in saved lists, search results, and map markers.

## Family map sharing

The app uses `iCloud.com.musaraj.harta`, with the CloudKit entitlement and `CKSharingSupported` declared in `project.yml`. In Xcode Signing & Capabilities / Apple Developer, enable iCloud with CloudKit for `com.musaraj.harta`, create or associate that container with team `M4XMDAF939`, and regenerate signing profiles. These account-side steps are not performed by XcodeGen or an unsigned simulator build.

The first development upload creates a `FamilyMap` record type with a `places` Asset field, in a custom `FamilyMap` zone. The fixed `FamilyMap` root record has a private `CKShare`; the sharing controller offers private, read-only invitations only. Deploy the development schema to production in CloudKit Console before TestFlight/App Store testing. Never enable public access to the map records.

For this owner-edits/viewer-reads version, the root asset is a JSON snapshot of saved places. CloudKit operations perform foreground synchronization instead of `CKSyncEngine`; no background push or instant delivery is promised. This keeps the first sharing implementation small. Move to per-place records and change-token synchronization if collections or write volume grow. The local store atomically persists places and their last cloud baseline, migrates legacy JSON arrays, merges changes by place ID, and rejects stale CloudKit writes. Different place edits merge; local pending edits win same-place conflicts on the next successful retry. Edits made during an upload remain pending. A failed request leaves local edits intact.

Participants use a separate read-only cache. Account identity is pinned at first cloud use; changing accounts blocks uploads until the original account is restored, rather than uploading the old account’s places to another account. Known sign-out, account mismatch, and confirmed removal clear joined-map access. An offline device can retain previously downloaded content until access can be checked. Reopening an invitation restores membership after signing back in. Joining another map replaces the previous joined-map cache, without modifying personal places.

Before release, use two physical devices with different iCloud accounts to verify:

- Create a share, invite a named participant with view-only access, and open the link with Harta terminated and already running.
- Add/remove places and change icons/tints on the owner. Refresh the viewer and confirm navigation/search use shared saved places while all editing actions remain disabled.
- Relaunch offline and confirm downloaded places persist. Edit the owner offline, reconnect, and confirm changes sync.
- Use a second owner device: edit different places, then the same place; verify merge policy and retry after a server-version conflict.
- Remove a member, stop sharing, and leave from the participant. Verify access removal clears the downloaded family map on the next refresh and personal places survive.
- Test signed-out/restricted iCloud, account changes, full iCloud storage, interrupted invitations, network failures, and production-schema/TestFlight invitations.

Unit coverage in `FamilyMapTests` checks mutation restrictions, merge/deletion semantics, in-flight edits, and persistence. These tests do not prove CloudKit provisioning, server authorization, or system invitation routing.
