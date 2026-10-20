import SwiftUI

struct MapSearchBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Search places", systemImage: "magnifyingglass")
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .accessibilityIdentifier("map.search")
    }
}
