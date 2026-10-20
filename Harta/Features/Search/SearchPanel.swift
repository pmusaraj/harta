import SwiftUI

struct SearchPanel: View {
    @Bindable var model: SearchModel
    let store: SavedPlacesStore
    let recents: RecentPlacesStore
    let latitude: Double
    let longitude: Double
    let onSelect: (Place) -> Void
    let onClose: () -> Void
    @FocusState private var focused: Bool
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Place or address", text: $model.query)
                    .focused($focused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("search.input")
                    .onSubmit(submit)
                if !model.query.isEmpty {
                    Button("Clear search", systemImage: "xmark.circle.fill") {
                        model.query = ""; focused = true
                    }.labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                }
                Button("Close search", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("search.close")
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
                    if model.isSearching {
                        HStack { ProgressView(); Text("Finding places…") }
                    } else if let error = model.errorMessage {
                        Text(error)
                        Button("Try again", action: submit)
                    } else if !model.results.isEmpty {
                        ForEach(model.results) { place in
                            row(place)
                            if place.id != model.results.last?.id { Divider() }
                        }
                    } else if model.hasSearched {
                        Text("No places found. Try another name or address.").foregroundStyle(.secondary)
                    } else {
                        if !recents.places.isEmpty {
                            HStack {
                                Text("Recent").font(.subheadline.bold()).foregroundStyle(.secondary)
                                Spacer()
                                Button("Clear", action: recents.clear)
                                    .accessibilityLabel("Clear recent places")
                                    .frame(minHeight: 44)
                            }
                            ForEach(recents.places) { place in
                                row(place)
                                if place.id != recents.places.last?.id { Divider() }
                            }
                        }
                        if !store.places.isEmpty {
                            Text("Saved").font(.subheadline.bold()).foregroundStyle(.secondary)
                            ForEach(store.places) { place in
                                row(place)
                                if place.id != store.places.last?.id { Divider() }
                            }
                        }
                        if recents.places.isEmpty && store.places.isEmpty {
                            Text("Enter a place or address, then tap Search.").foregroundStyle(.secondary)
                        }
                    }
                    Text("Photon · OpenStreetMap").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .frame(height: min(contentHeight, 280))
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        .clipShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("search.panel")
        .onChange(of: model.query) { model.queryChanged() }
        .task { recents.reload(); focused = true }
        .onDisappear { model.cancel() }
    }
    private func row(_ place: Place) -> some View {
        SearchPlaceRow(place: place, store: store) { selected in
            recents.record(selected)
            focused = false
            onSelect(selected)
        }
    }
    private func submit() {
        focused = false
        _ = model.submit(latitude: latitude, longitude: longitude)
    }
}
