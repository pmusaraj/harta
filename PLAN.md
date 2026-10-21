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


## Voice commands — implemented scope

Implemented October 20, 2026: tap-to-speak commands extract a basic search or
route-preview request and reuse existing search, saved places, and directions.
Automated tests cover extraction fallback, saved-place matching, cancellation,
permission/error handling, and audio conversion. Real-device speech recognition,
model quality/latency, accents, noisy environments, and navigation audio remain
manual validation tasks; simulator service doubles do not establish speech accuracy.
No chat interface, rich place filters, or visible transcript by default.

### Interaction

- Add a microphone action beside search. Show accessible Listening and Processing
  states, a stop action, and cancellation. Capture only during an explicit session.
- Keep interim and final transcription internal. Show matching places or the route
  preview directly; ordinary text search remains available for correcting a query.
- End recording when the user stops or after a bounded silence/recording timeout.
  Do not interpret a partial transcript or treat each finalized segment as a command.
- Report short actionable errors for no speech, missing microphone permission,
  unavailable language assets, and failed recognition. Allow retry or typed search.
- On ambiguity, show a small place chooser. Do not automatically start navigation;
  retain the existing Start navigation action on the route preview.

### Local transcription and extraction

1. Capture microphone audio with AVAudioEngine and transcribe with SpeechAnalyzer
   and SpeechTranscriber. Check hardware, locale, and installed assets; download
   required assets with progress. Use DictationTranscriber as a supported fallback.
2. Pass only the completed utterance to an on-device Foundation Models session.
   Use guided generation for a small typed request: action (search or directions),
   query/destination text, optional saved-place reference (home/work/name), optional
   explicit locality text, and optional walking/cycling/driving mode. Missing fields
   remain absent; preserve the user's destination name and existing travel default.
3. Validate output against supported actions. The model extracts text and intent;
   application code resolves saved IDs, locations, and routes. Never generate
   coordinates or use model knowledge to invent places or opening hours.
4. Check speech and LLM availability separately. When extraction is unavailable,
   use a small deterministic parser for explicit commands such as “go home” and
   “directions to work”; otherwise submit recognized destination text as basic search.
   No silent cloud speech or language-model fallback.

### Saved places first

- Resolve saved references locally before calling Photon. Normalize case,
  diacritics, whitespace, and punctuation for matching saved names.
- “Home”, “go home”, and “directions home” match a saved place named Home or marked
  with the Home icon. Apply the same rule to Work. Do not infer home from GPS history.
- Exact normalized saved-name matches take priority. Multiple exact candidates,
  including multiple Home/Work places, require a chooser. Broader matches appear
  alongside online results instead of automatically opening one saved place.
- Resolve a unique saved place directly using its stored coordinates. For directions,
  open the existing preview with current location as origin and the extracted mode
  or current mode default. Handle unavailable location through the existing flow.
- If Home or Work is missing, explain how to save a place with that name or icon;
  do not send “home” or “work” as a generic online destination search.
- Other names go through combined saved and submit-only Photon search, preferring
  a fresh current location. Explicit map-area requests use the map center; named
  localities remain in the query and omit coordinate bias.
  Saved-place resolution must respect explicit locality qualifiers rather than
  silently replacing an out-of-town destination with a similarly named saved place.

### Basic search boundary

- “Find tennis clubs” → search query “tennis clubs”.
- “Find coffee in Montreal” → search query “coffee in Montreal”.
- “Walking directions to Central Library” → match saved places first, otherwise show
  Photon results; selecting a result opens a walking route preview.
- “Go home” → resolve saved Home locally, then show a route preview.
- No opening-hours, prices, ratings, availability, radius, or other rich filtering.
  If requested, explain that the filter is unsupported rather than imply it applied.
- Audio and extraction stay on device once assets are ready. Unmatched submitted
  queries still reach Photon, and directions still use the online routing service.
  Update privacy text and microphone usage description when implementing.

### Architecture and remaining verification

- Use injectable transcription and command-extraction services, a typed voice
  request, and a deterministic saved-place resolver, coordinated by a cancellable
  voice-command model. Reuse SearchModel, SavedPlacesStore, and directions behavior.
  Speech capture stops after 0.8 seconds without detected speech following speech,
  eight seconds with no speech, or twenty seconds total. Stop submits; Cancel discards.
  Local recognition finalization and command extraction also have bounded waits.
- Cancel audio, extraction, and pending searches on dismissal or replacement; reject
  stale results. Coordinate microphone capture with spoken navigation guidance.
- Test exact/partial/ambiguous saved matches, Home/Work aliases, absent saved places,
  explicit locality, travel modes, malformed extraction, cancellation, unavailable
  models, missing permissions, and no-speech recovery using service doubles.
- On real devices, measure latency and recognition quality for local street names,
  accents, noise, supported languages, and interaction with navigation audio. Verify
  VoiceOver announces state and results without requiring a transcript on screen.

References: [Apple speech pipeline](https://developer.apple.com/videos/play/wwdc2025/277/),
[Foundation Models](https://developer.apple.com/documentation/foundationmodels),
[guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation).


## Search quality — stage one

Implemented shared typed/voice search with immediate saved matches followed by
merged online results. Matching uses normalized tokens, small typos, and explicit
sport/category icons. Rank by name relevance, saved status, and distance; exact
named destinations retain priority. Merge duplicate IDs and same-name nearby points,
preserving saved metadata. Keep saved results visible if online search fails.

“Near me” is a current-location scope, never query text or a named locality. Use a
fix less than two minutes old. Without one, offer location recovery or explicit
map-area search. Ordinary searches may fall back to the map center with a notice.
Named localities take precedence and only include saved places whose names/addresses
match that locality; they do not inherit an unrelated GPS bias.

## Search quality — stage two (deferred)

Extend local-model involvement beyond voice intent extraction: use it to interpret
category/name variations, expand queries, and assess retrieved candidates. Ground
all results in actual saved/provider places. Evaluate against real failed queries
before choosing the model prompts and ranking behavior. Do not invent destinations.
