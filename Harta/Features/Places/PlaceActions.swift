import SwiftUI

struct PlaceActions: View {
    let place: Place
    let isSaved: Bool
    let onSave: () -> Void
    let onDirections: () -> Void

    var body: some View {
        Button("Directions", systemImage: "arrow.turn.up.right", action: onDirections)
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("place.directions")
        Button(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark", action: onSave)
            .accessibilityIdentifier("place.save")
            .buttonStyle(.bordered)
            .accessibilityHint(isSaved ? "Remove from saved places" : "Save on this device")
        ShareLink(item: place.shareURL, subject: Text(place.name), message: Text(place.name)) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
    }
}
