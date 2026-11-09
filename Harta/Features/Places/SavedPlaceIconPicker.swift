import SwiftUI

struct SavedPlaceIconPicker: View {
    let place: Place
    let store: SavedPlacesStore
    @State private var query = ""
    @State private var icons = SavedPlaceIcon.allCases
    @State private var isLoading = true
    @State private var catalogError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(place.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let error = store.errorMessage {
                        Text(error).foregroundStyle(.red)
                    }
                    if let catalogError { Text(catalogError).foregroundStyle(.secondary) }
                    if isLoading { ProgressView("Loading icons…") }
                    if icons.isEmpty && !isLoading {
                        ContentUnavailableView.search(text: query)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 16) {
                        ForEach(icons) { icon in
                            Button { choose(icon) } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: icon.symbol)
                                        .font(.title2)
                                        .frame(width: 48, height: 48)
                                        .background(.teal.opacity(0.12), in: .circle)
                                        .overlay(alignment: .bottomTrailing) {
                                            if store.icon(for: place) == icon {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .symbolRenderingMode(.palette)
                                                    .foregroundStyle(.white, .teal)
                                                    .font(.body)
                                            }
                                        }
                                    Text(icon.title).font(.caption).lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.teal)
                            .accessibilityLabel(icon.title)
                            .accessibilityValue(store.icon(for: place) == icon ? "Selected" : "Not selected")
                            .accessibilityIdentifier("saved.icon.option.\(icon.rawValue)")
                        }
                    }
                }
                .padding()
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search icons, e.g. bicycle or heart")
            .autocorrectionDisabled()
            .task(id: query) { await search() }
            .navigationTitle("Choose an icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func search() async {
        isLoading = true
        catalogError = nil
        do {
            if !query.isEmpty { try await Task.sleep(for: .milliseconds(150)) }
            var matches = try await SymbolCatalog.shared.matching(query)
            try Task.checkCancellation()
            // Permit exact names introduced after the bundled catalog was generated.
            let name = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !name.isEmpty, let exact = SavedPlaceIcon(systemName: name) {
                matches.removeAll { $0 == exact }
                matches.insert(exact, at: 0)
            }
            icons = matches
            isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            icons = SavedPlaceIcon.allCases.filter {
                SymbolCatalog.matches(query, text: $0.title + " " + $0.symbol)
            }
            catalogError = "The full icon catalog couldn’t load. Common icons are still available."
            isLoading = false
        }
    }

    private func choose(_ icon: SavedPlaceIcon) {
        if store.setIcon(icon, for: place) { dismiss() }
    }
}
