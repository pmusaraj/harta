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

Search sends the submitted query and visible map center to Photon. Tile requests disclose viewed areas to OpenFreeMap. Routing sends origin/destination coordinates and travel mode to FOSSGIS. Automatic rerouting sends the current position again. All providers receive the device’s IP address. Saved places are a local JSON file in Application Support. The last ten selected search places and travel-mode and map-style preferences stay locally in UserDefaults; recent places can be cleared in search. Maps/search/routing require connectivity; cache availability is not an offline feature.

The map requests location on launch, centers on the first fresh fix, and keeps its location dot updated while active. Browsing uses best accuracy with a five-meter distance filter and resumes updates when the app returns to the foreground. Montreal is the fallback while locating or if permission is denied. Panning or choosing a destination cancels automatic recentering; the location button explicitly recenters.

Routing references: [Valhalla API](https://valhalla.github.io/valhalla/api/), [public demo usage](https://github.com/valhalla/valhalla#demo-server).

## Project notes

- [TestFlight distribution](TESTFLIGHT.md): signing, uploads, and tester setup.
- [PLAN.md](PLAN.md): scope and milestones.
- [Harta](README.md): app overview.
