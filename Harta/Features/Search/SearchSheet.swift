import SwiftUI

/// Used for origin selection; destination search is presented directly over the map.
struct SearchSheet: View {
    @Bindable var model: SearchModel
    let store: SavedPlacesStore
    let latitude: Double
    let longitude: Double
    let onSelect: (Place) -> Void
    @State private var recents = RecentPlacesStore()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SearchPanel(model: model, store: store, recents: recents, latitude: latitude, longitude: longitude,
                    onSelect: onSelect, onClose: { dismiss() })
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .presentationDragIndicator(.visible)
    }
}
