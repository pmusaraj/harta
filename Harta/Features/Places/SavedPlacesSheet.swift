import SwiftUI

struct SavedPlacesSheet: View {
    let store: SavedPlacesStore
    let onSelect: (Place) -> Void
    @State private var editingIconFor: Place?
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
                    HStack(spacing: 12) {
                        Button { editingIconFor = place } label: {
                            Image(systemName: place.icon.symbol)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(.teal.opacity(0.12), in: .circle)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.teal)
                        .accessibilityLabel("Change icon for \(place.name)")
                        .accessibilityValue(place.icon.title)
                        .accessibilityIdentifier("saved.icon.\(place.id)")
                        Button { onSelect(place) } label: {
                            PlaceRow(place: place).contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("saved.place.\(place.id)")
                    }
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
        .sheet(item: $editingIconFor) { place in
            SavedPlaceIconPicker(place: place, store: store)
        }
    }

    private func delete(at offsets: IndexSet) {
        store.remove(ids: Set(offsets.map { store.places[$0].id }))
    }

    private func close() { dismiss() }
}
