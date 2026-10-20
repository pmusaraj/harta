import SwiftUI

struct SearchPlaceRow: View {
    let place: Place
    let store: SavedPlacesStore
    let onSelect: (Place) -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button { onSelect(place) } label: {
                PlaceRow(place: place).frame(maxWidth: .infinity, alignment: .leading).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("search.place.\(place.id)")
            Button { store.toggle(place) } label: {
                Image(systemName: store.contains(place) ? "bookmark.fill" : "bookmark")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.teal)
            .accessibilityLabel(store.contains(place) ? "Unsave \(place.name)" : "Save \(place.name)")
            .accessibilityIdentifier("search.save.\(place.id)")
        }
    }
}
