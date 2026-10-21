import SwiftUI

struct SavedPlaceIconPicker: View {
    let place: Place
    let store: SavedPlacesStore
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 16) {
                        ForEach(SavedPlaceIcon.allCases) { icon in
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
                                    Text(icon.title).font(.caption)
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

    private func choose(_ icon: SavedPlaceIcon) {
        if store.setIcon(icon, for: place) { dismiss() }
    }
}
