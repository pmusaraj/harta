# Development

Harta (`com.musaraj.harta`) is a native SwiftUI iOS prototype with MapLibre Native. iOS 26+, Xcode 26+.

Open `Harta.xcodeproj`, select the **Harta** scheme and an iOS 26 simulator, then Run. Swift Package Manager downloads the pinned MapLibre 6.31.0 and Ferrostar 0.57.0 SDKs. No API key is needed for the prototype.

For a physical device, select your development team in Signing & Capabilities. The bundle identifier is `com.musaraj.harta`. The app includes the selected Route H icon (concept 3B).

## Build and test

`project.yml` is the project source of truth. After adding files, regenerate the checked-in Xcode project using [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
xcodebuild -project Harta.xcodeproj -scheme Harta \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Run unit and UI tests with Product → Test in Xcode on an iOS 26 simulator. The live routing UI smoke test is opt-in: pass `RUN_LIVE_ROUTING_TESTS=1` to xcodebuild, grant simulator location permission, and set its location to `43.6426,-79.3871` (near the Toronto default destination). It calls the public routing service; normal tests do not.

## Map layers

All six overlays use the existing OpenFreeMap tiles, with no extra API or credentials. Colored 22-point circular place badges with white symbols and borders appear from zoom 14, with generous tap targets. Cycling highlights appear from zoom 12 as green dashed lines. Essentials distinguishes groceries (orange basket), corner stores (blue storefront), pharmacies (green medical case), and ATMs (teal banknote). Transit uses blue bus symbols and purple metro, rail, tram, and ferry symbols. Metro/subway entrances use an M symbol; generic railway stations remain rail markers when tiles do not specify the mode. Cycling highlights mapped cycleways and paths tagged for designated/official bicycle use; it is not a complete bike-lane network or a change to route planning.

Coverage follows OpenStreetMap/OpenMapTiles and varies by region. These layers do not provide live charger or parking availability, transit departures, opening hours, or access guarantees. Existing base-style labels remain independent of the optional overlays. The generator in `scripts/map-styles/overlays.py` defines filters and appearance for all eight bundled styles.

## Service boundaries

MapLibre is the native renderer. Valhalla supplies online routes through the configurable FOSSGIS demo endpoint (`https://valhalla1.openstreetmap.de/route`). Preview requests are explicit, cancellable, and throttled to at most one per second per service instance. Navigation requests use Ferrostar’s Valhalla adapter with voice/banner instructions; automatic rerouting waits at least 15 seconds and 15 meters of movement between attempts. The public demo is for modest prototype use; choose production hosting before release. OpenFreeMap provides online tiles and styles. Photon’s public demo provides modest prototype search traffic only. Before public release, choose production search hosting and validate coverage, limits, privacy terms, and attribution. Endpoint configuration is in `AppConfiguration.swift`; bundled map styles are in `Harta/Resources/MapStyles`. Regenerate all eight style files with `python3 scripts/map-styles/generate.py`; upstream base snapshots and license notices are retained.

Search sends the submitted query and a fresh current-location bias to Photon by default, falling back visibly to the map center. Explicit map-area requests use the map center; named localities omit coordinate bias. Tile requests disclose viewed areas to OpenFreeMap. Routing sends origin/destination coordinates and travel mode to FOSSGIS. Automatic rerouting sends the current position again. All providers receive the device’s IP address. Saved places are a local JSON file in Application Support. The last ten selected search places and travel-mode and map-style preferences stay locally in UserDefaults; recent places can be cleared in search. Maps/search/routing require connectivity; cache availability is not an offline feature.

The map requests location on launch, centers on the first fresh fix, and keeps its location dot updated while active. Browsing uses best accuracy with a five-meter distance filter and resumes updates when the app returns to the foreground. Montreal is the fallback while locating or if permission is denied. Panning or choosing a destination cancels automatic recentering; the location button explicitly recenters.

Routing references: [Valhalla API](https://valhalla.github.io/valhalla/api/), [public demo usage](https://github.com/valhalla/valhalla#demo-server).

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
merges other saved matches with Photon results using PlaceSearchRanking: normalized
name tokens, conservative one-edit typos, sport/category icons, saved status, and
distance. Saved results appear before the network completes and survive failures.
Duplicate IDs or matching names within 50 metres collapse to the saved record.
Explicit named localities filter saved addresses/names and omit GPS bias in Photon.
PlaceSearchRequest separates current location, map area, and named locality.
Photon requests up to 20 results with location_bias_scale=0.1 when biased.
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
