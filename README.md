# Harta

Harta is a maps and navigation app for iPhone and iPad. Find places, save your favorites, and get walking, cycling, or driving directions.

Harta is currently a prototype. It requires iOS/iPadOS 26 or later and an internet connection. No account is needed.

## Explore and navigate

- Search for a destination, browse recent searches, or press and hold the map to drop a pin.
- Tap the microphone in Search to find places or ask for directions. Try “find tennis clubs,” “walking directions to Central Library,” or “go home.”
- Save places for later and share them with others.
- Preview routes with travel time, distance, and written directions.
- Follow turn-by-turn navigation with optional spoken guidance and automatic rerouting.
- Choose from four map styles—Quiet, Everyday, Walking, and Explore—with light and dark appearances.
- Show nearby EV chargers, toilets, parking, cycling paths, transit, and everyday essentials.

Choose a destination and tap **Go** to preview a route, then **Start navigation** when you're ready. Navigation needs Precise Location permission. Voice guidance starts muted; turn it on to hear directions. Guidance can continue with the screen locked. Tap **End** to stop navigation.

Open **Search** above the location control to find a place, or **Layers** beside it to choose what appears on the map. Open **Settings** in the top-right corner to change the map style, read privacy information, or view map credits.

In **Saved places**, tap the icon beside a place to choose a different symbol. Sports venues receive a matching icon automatically when their name identifies a sport; other saves use a bookmark. Your chosen icon overrides automatic detection. Your choice appears in the saved list, search results, and on the map; tap the place’s name to open its details.

Voice search keeps transcripts hidden and shows matching places or a directions preview. Exact saved destinations are matched first; broader searches combine saved and online places, with saved matches labeled. Sport icons and small name variations help match saved places. “Home” and “work” also match those saved icons. If an exact saved name or Home/Work matches several places, choose one. Voice directions never start navigation automatically. Voice search supports basic place searches, not opening-hours, price, or rating filters.

Speech recognition runs on device using your device language and may need a first-time language download. Apple Intelligence improves command extraction when available; a basic English command parser remains available otherwise. Device and language support vary. You can always type instead.

Search prefers your current location when available. “Near me” requires a recent location fix; “in this area” searches around the map center. A named locality such as “in Toronto” takes precedence. If current location is unavailable, ordinary searches explain their map-area fallback. Saved matches remain visible when online search fails.

## Privacy

Voice audio and transcripts are processed on device and are not saved or uploaded. Unmatched voice destinations use the same online search as typed queries. Saved places, recent searches, and preferences stay on your device. Harta has no analytics. Background location is used only during active navigation.

Online services receive the information needed to respond: Photon receives submitted searches and, when used, the current-location or map-center search bias, OpenFreeMap receives map tile requests, and FOSSGIS receives route coordinates and travel mode. These providers also receive your IP address. You can clear recent searches in the app.

## Current limitations

Offline maps and routing, live traffic, CarPlay, and Live Activities are not available. Navigation does not resume automatically after the app is terminated. Map coverage varies by region; place layers do not provide live availability, opening hours, or transit departures.

Harta is still being tested for navigation accuracy, background guidance, and battery use.

## Project documentation

- [Development](DEVELOPMENT.md): building, testing, and technical details.
- [TestFlight distribution](TESTFLIGHT.md): signing and uploading beta builds.
