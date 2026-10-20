import SwiftUI

struct MapSearchBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Search places", systemImage: "magnifyingglass")
                .labelStyle(.iconOnly)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: .circle)
        .accessibilityIdentifier("map.search")
    }
}
