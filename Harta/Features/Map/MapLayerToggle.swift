import SwiftUI

struct MapLayerToggle: View {
    let overlay: MapOverlay
    @AppStorage(MapOverlay.preferenceKey) private var selection = 0

    private var enabled: Binding<Bool> {
        Binding {
            overlay.isEnabled(in: selection)
        } set: { enabled in
            if enabled { selection |= overlay.rawValue }
            else { selection &= ~overlay.rawValue }
        }
    }

    var body: some View {
        Toggle(isOn: enabled) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(overlay.title)
                    Text(overlay.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: overlay.symbol)
            }
        }
        .accessibilityIdentifier("layers.\(overlay.key)")
    }
}
