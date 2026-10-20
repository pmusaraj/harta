import SwiftUI

struct MapSearchBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Search places", systemImage: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .accessibilityIdentifier("map.search")
    }
}
