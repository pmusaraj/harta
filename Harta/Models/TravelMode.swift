import Foundation

enum TravelMode: String, CaseIterable, Identifiable, Sendable {
    case walking = "pedestrian", cycling = "bicycle", driving = "auto"
    var id: String { rawValue }
    var title: String {
        switch self { case .walking: "Walk"; case .cycling: "Cycle"; case .driving: "Drive" }
    }
}
