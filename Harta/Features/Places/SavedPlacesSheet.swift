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
                                           description: Text("Search for a place or drop a pin, then tap Save."))
                }
                ForEach(store.places) { place in
                    HStack(spacing: 12) {
                        Button { editingIconFor = place } label: {
                            Image(systemName: place.icon.symbol)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(place.tint.color.opacity(0.12), in: .circle)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isReadOnly)
                        .foregroundStyle(place.tint.color)
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
                .deleteDisabled(store.isReadOnly)
            }
            .navigationTitle(store.isReadOnly ? "Shared places" : "Saved places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.isReadOnly && !store.places.isEmpty { EditButton() }
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
