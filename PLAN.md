# Harta implementation plan

## Agreed direction

- Native SwiftUI iOS app first; native Kotlin Android app later.
- MapLibre Native renders the map. UIKit is confined to its SwiftUI adapter.
- Priorities: clean UI, responsive interaction, low battery and network usage.
- Offline downloads are not a v1 requirement. No account or analytics. Background location is limited to explicitly started navigation.
- Build a custom app rather than fork CoMaps or Organic Maps.

## First working slice

Implemented and verified in the iOS Simulator on October 12, 2026. Real-device efficiency measurements remain a next milestone.

1. Create a reproducible Xcode project, iOS 26+, Swift 6.
2. Keep one MapLibre view mounted behind the SwiftUI interface.
3. Use OpenFreeMap Positron/light and Dark styles; retain map attribution.
4. Add one-shot, user-initiated location with denial and failure states.
5. Add submit-only Photon search, bounded caching, cancellation, and nearby bias.
6. Select a search result or long-press to drop a pin; provide an accessible center-pin action.
7. Show place details with save, share, and directions (initial Apple Maps handoff replaced by in-app previews).
8. Store favorites locally with recoverable persistence errors.
9. Build and run in Simulator; test parsing, persistence, and search state correctness.

## Next milestones

- Validate search/address coverage in the intended launch regions.
- Select production search hosting; Photon public demo is for modest prototype traffic only.
- Validate bundled map styles across more regions and zoom levels; complete the broader provider/font license audit before release.
- Measure cold start, frame pacing, memory, data usage, and battery on real devices.
- Test VoiceOver, largest Dynamic Type, Reduce Motion, denied location, poor networks.
- App icon, localization, privacy disclosures, signing and store preparation.
- Android implementation after iOS interaction design stabilizes.
- In-app route preview and written steps are implemented. Live navigation is implemented in the increment below; offline downloads remain deferred.

## Constraints and implementation choices

OpenFreeMap is a free public service without an SLA. Photon demo usage is limited to reasonable traffic and has no availability guarantee. Keep endpoints replaceable. Do not use the public Nominatim endpoint for autocomplete. Map tiles/search are external requests; local favorites do not sync. Cached tiles are not a promised offline mode.

Browsing uses one-shot location; the navigation increment uses continuous location only during active guidance. Map movement callbacks update state only after the camera settles. Use native map annotations for the small selection/location set. No per-frame SwiftUI state updates.

## Sources

- https://github.com/maplibre/maplibre-native-distribution
- https://openfreemap.org/quick_start/
- https://github.com/komoot/photon
- https://github.com/komoot/photon/blob/master/docs/api-v1.md

See DEVELOPMENT.md for build and verification instructions.

## Directions increment

Implemented configurable Valhalla routing, walking/cycling/driving selection, current-location or searched origin, route overlay, duration/distance, and tappable steps that highlight the map. Route state cancels and rejects stale responses. Public FOSSGIS routing is a prototype dependency; production hosting and real-device checks remain pending.

## Navigation increment

Ferrostar Core powers a custom SwiftUI guidance screen with live GPS, upcoming maneuvers, speech, mute, progress, arrival, rerouting, and End. GPS/audio background modes support locked-screen guidance. Physical field validation and production route hosting remain release prerequisites.

## Settings and map styles

Everyday is the default map style. Settings beside Search offers Quiet, Everyday, Walking, and Explore, remembers the choice, and applies it to browsing and navigation in light and dark appearance. Privacy and map credits share this screen. The overflow menu is removed; pin dropping remains available by long press and an accessibility action. Styles are bundled, generated from retained OpenFreeMap snapshots, and include upstream license notices.
