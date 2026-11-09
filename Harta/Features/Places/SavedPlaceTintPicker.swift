import SwiftUI

struct SavedPlaceTintPicker: View {
    let place: Place
    let store: SavedPlacesStore
    @ScaledMetric(relativeTo: .caption) private var swatchWidth = 52

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: (store.icon(for: place) ?? place.icon).symbol)
                    .font(.title)
                    .foregroundStyle(store.tint(for: place).color)
                    .frame(width: 56, height: 56)
                    .background(store.tint(for: place).color.opacity(0.12), in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name).font(.headline)
                    Text("Symbol tint · \(store.tint(for: place).title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: swatchWidth), spacing: 8)], spacing: 12) {
                ForEach(SavedPlaceTint.allCases) { tint in
                    Button { store.setTint(tint, for: place) } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(tint.color)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if store.tint(for: place) == tint {
                                        Image(systemName: "checkmark")
                                            .font(.body.bold())
                                            .foregroundStyle(Color(uiColor: .systemBackground))
                                    }
                                }
                                .frame(height: 44)
                            Text(tint.title).font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tint.title)
                    .accessibilityValue(store.tint(for: place) == tint ? "Selected" : "Not selected")
                    .accessibilityIdentifier("saved.tint.option.\(tint.rawValue)")
                }
            }
        }
    }
}
