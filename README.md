# Harta

Harta is a maps and navigation app for iPhone and iPad. Find places, save your favorites, and get walking, cycling, or driving directions.

Harta is currently a prototype. It requires iOS/iPadOS 26 or later and an internet connection. No user account is needed. Builds require a Stadia Maps API key for online search and routing (see Development).

## Explore and navigate

- Search for a destination, browse recent searches, or press and hold the map to drop a pin.
- Tap the microphone in Search to find places or ask for directions. Try “find tennis clubs,” “walking directions to Central Library,” or “go home.”
- Save places for later and share them with others.
- See an estimated travel time for your destination before starting navigation.
- Follow turn-by-turn navigation with optional spoken guidance and automatic rerouting.
- Choose from four map styles—Quiet, Everyday, Walking, and Explore—with light and dark appearances.
- Show nearby EV chargers, toilets, parking, cycling paths, transit, and everyday essentials.

Choose a destination and tap **Go** to start navigation. Navigation needs Precise Location permission. Voice guidance starts muted; turn it on to hear directions. Guidance can continue with the screen locked. Tap **End** to stop navigation.

Open **Search** above the location control to find a place, or **Layers** beside it to choose what appears on the map. Open **Settings** in the top-right corner to change the map style, read privacy information, or view map credits.

In a saved place’s details, touch and hold its name to rename it. Renaming preserves its location, icon, and colour, and syncs to family members when sharing is enabled. Family members with view-only access cannot rename places.

In **Saved places** or a saved place’s details, tap the icon beside its name to choose a different symbol. Choose a symbol tint from Teal (the default), Blue, Purple, Pink, Orange, or Green; the selected tint has a checkmark and updates the live preview. Search the SF Symbols catalog by name or keyword, or enter an exact system symbol name. Only symbols supported on your device are offered. Sports venues receive a matching icon automatically when their name identifies a sport; other saves use a bookmark. Your chosen icon overrides automatic detection. Your choice appears in the saved list, search results, and on the map; tap the place’s name to open its details.

Voice search keeps transcripts hidden and shows matching places or a destination card. Exact saved destinations are matched first; broader searches combine saved and online places, with saved matches labeled. Sport icons and small name variations help match saved places. “Home” and “work” also match those saved icons. If an exact saved name or Home/Work matches several places, choose one. Voice directions never start navigation automatically. Voice search supports basic place searches, not opening-hours, price, or rating filters.

Speech recognition runs on device using your device language and may need a first-time language download. Apple Intelligence improves command extraction when available; a basic English command parser remains available otherwise. Device and language support vary. You can always type instead.

Search prefers your current location when available. “Near me” requires a recent location fix; “in this area” searches around the map center. A named locality such as “in Toronto” takes precedence. If current location is unavailable, ordinary searches explain their map-area fallback. Saved matches remain visible when online search fails.

## Privacy

Voice audio and transcripts are processed on device and are not saved or uploaded. Unmatched voice destinations use the same online search as typed queries. Saved places stay on your device unless you enable family sharing. Shared places are stored in iCloud and downloaded to invited members’ devices. Recent searches and preferences stay on your device. Harta has no analytics. Background location is used only during active navigation.

Online services receive the information needed to respond: Stadia Maps receives search text (including partial queries), selected place identifiers and, when used, the current-location or map-center search bias, OpenFreeMap receives map tile requests, and Stadia Maps receives route coordinates and travel mode. These providers also receive your IP address. You can clear recent searches in the app.

## Current limitations

Offline maps and routing, live traffic, CarPlay, and Live Activities are not available. Navigation does not resume automatically after the app is terminated. Map coverage varies by region; place layers do not provide live availability, opening hours, or transit departures.

Harta is still being tested for navigation accuracy, background guidance, and battery use.

## Project documentation

- [Development](DEVELOPMENT.md): building, testing, and technical details.
- [TestFlight distribution](TESTFLIGHT.md): signing and uploading beta builds.

## Shared maps

In Settings → Shared map, choose **Share my saved places** to upload your saved places to iCloud and invite people using Apple’s sharing sheet. Choose view-only or editing access for invited members. Editors can add, rename, customize, and remove places, and their changes sync to everyone. Existing members remain view-only until the owner grants editing access. Everyone needs an active iCloud account. Invitations are explicit and do not require Apple Family Sharing membership. CloudKit supports up to 100 participants per share ([Apple documentation](https://developer.apple.com/documentation/cloudkit/ckshare)).

Open the invitation link on a device with Harta installed to join. Members can switch between the shared map and their personal saved places in Settings. Joining does not overwrite personal places. Use **Manage membership** to leave; owners use **Manage my map’s sharing** to remove members or stop sharing.

Changes sync when Harta is active, including a refresh about every 30 seconds, and through **Sync now**. Downloaded saved places remain available offline; map tiles, search, and routing still need connectivity. Live location, recent searches, and navigation sessions are not shared. Revoked access is detected on the next successful cloud check, not while a device is offline.

This first version supports one joined shared map per installation. Open the invitation on each device that should join. CloudKit provisioning and testing with separate iCloud accounts are required before distributing this feature; see Development.

Shared-map editing unlocks after a successful permission check each launch. Once verified, edits can be saved offline and upload when connectivity returns. Independent place edits merge; pending local changes win conflicts on the same place. If editing permission is revoked, unsent edits stay on the device and can sync if editing access is restored. Leaving, losing access, or joining a different map clears the joined-map cache, including unsent edits. Personal places are preserved.
