import SwiftUI

struct MapControls: View {
    let isLocating: Bool
    let onSaved: () -> Void
    let onLocate: () -> Void
    let onSearch: () -> Void
    let onLayers: () -> Void
    @AppStorage(MapOverlay.preferenceKey) private var selection = 0

    var body: some View {
        HStack(alignment: .bottom) {
            Button("Saved", systemImage: "bookmark", action: onSaved)
                .accessibilityIdentifier("map.saved")
                .padding(.horizontal)
                .frame(minHeight: 48)
                .background(.regularMaterial, in: .capsule)
            Spacer()
            Button(action: onLayers) {
                Label("Layers", systemImage: "square.3.layers.3d")
                    .labelStyle(.iconOnly)
                    .overlay(alignment: .topTrailing) {
                        if MapOverlay.enabledCount(in: selection) > 0 {
                            Text(MapOverlay.enabledCount(in: selection).formatted())
                                .font(.caption2.bold())
                                .padding(4)
                                .background(.regularMaterial, in: .circle)
                                .offset(x: 12, y: -12)
                                .accessibilityHidden(true)
                        }
                    }
            }
            .frame(width: 48, height: 48)
            .background(.regularMaterial, in: .circle)
            .accessibilityLabel("Map layers")
            .accessibilityValue("\(MapOverlay.enabledCount(in: selection)) enabled")
            .accessibilityIdentifier("map.layers")
            VStack(spacing: 12) {
                MapSearchBar(action: onSearch)
                Button(action: onLocate) {
                    if isLocating {
                        ProgressView().accessibilityLabel("Finding your location")
                    } else {
                        Label("Show my location", systemImage: "location")
                            .labelStyle(.iconOnly)
                    }
                }
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: .circle)
                .disabled(isLocating)
                .accessibilityIdentifier("map.locate")
            }
        }
        .buttonStyle(.plain)
        .font(.body)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
}
