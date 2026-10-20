import SwiftUI

struct SavedPlacesSheet: View {
    let store: SavedPlacesStore
    let onSelect: (Place) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                }
                if store.places.isEmpty {
                    ContentUnavailableView("Your places, close by", systemImage: "bookmark",
                                           description: Text("Search for a place or drop a pin, then tap Save. Your places stay on this device."))
                }
                ForEach(store.places) { place in
                    Button { onSelect(place) } label: { PlaceRow(place: place) }
                        .tint(.primary)
                        .accessibilityIdentifier("saved.place.\(place.id)")
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Saved places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.places.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .confirmationAction) { Button("Done", action: close) }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func delete(at offsets: IndexSet) {
        store.remove(ids: Set(offsets.map { store.places[$0].id }))
    }

    private func close() { dismiss() }
}
