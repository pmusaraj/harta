# Harta

Harta is a maps and navigation app for iPhone and iPad. Find places, save your favorites, and get walking, cycling, or driving directions.

Harta is currently a prototype. It requires iOS/iPadOS 26 or later and an internet connection. No account is needed.

## Explore and navigate

- Search for a destination, browse recent searches, or press and hold the map to drop a pin.
- Save places for later and share them with others.
- Preview routes with travel time, distance, and written directions.
- Follow turn-by-turn navigation with optional spoken guidance and automatic rerouting.
- Choose from four map styles—Quiet, Everyday, Walking, and Explore—with light and dark appearances.
- Show nearby EV chargers, toilets, parking, cycling paths, transit, and everyday essentials.

Choose a destination and tap **Go** to preview a route, then **Start navigation** when you're ready. Navigation needs Precise Location permission. Voice guidance starts muted; turn it on to hear directions. Guidance can continue with the screen locked. Tap **End** to stop navigation.

Open **Search** above the location control to find a place, or **Layers** beside it to choose what appears on the map. Open **Settings** in the top-right corner to change the map style, read privacy information, or view map credits.

In **Saved places**, tap the icon beside a place to choose a different symbol. New saves use a bookmark. Your choice appears in the saved list, search results, and on the map; tap the place’s name to open its details.

## Privacy

Saved places, recent searches, and preferences stay on your device. Harta has no analytics. Background location is used only during active navigation.

Online services receive the information needed to respond: Photon receives submitted searches and the map center, OpenFreeMap receives map tile requests, and FOSSGIS receives route coordinates and travel mode. These providers also receive your IP address. You can clear recent searches in the app.

## Current limitations

Offline maps and routing, live traffic, CarPlay, and Live Activities are not available. Navigation does not resume automatically after the app is terminated. Map coverage varies by region; place layers do not provide live availability, opening hours, or transit departures.

Harta is still being tested for navigation accuracy, background guidance, and battery use.

## Project documentation

- [Development](DEVELOPMENT.md): building, testing, and technical details.
- [TestFlight distribution](TESTFLIGHT.md): signing and uploading beta builds.
