import SwiftUI

struct MapCredits: View {
    var body: some View {
        QuarterTurnLayout {
            HStack(spacing: 8) {
                Link("© OpenStreetMap", destination: AppConfiguration.osmCredit)
                Link("© OpenMapTiles", destination: AppConfiguration.tilesCredit)
            }
            .font(.caption2)
            .tint(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.regularMaterial, in: .capsule)
            .fixedSize()
            .rotationEffect(.degrees(90))
        }
        .accessibilityIdentifier("map.credits")
    }
}
