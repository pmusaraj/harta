import Foundation

enum MapStyle: String, CaseIterable, Identifiable {
    case quiet, everyday, walking, explore

    static let preferenceKey = "mapStyle"
    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiet: "Quiet"
        case .everyday: "Everyday"
        case .walking: "Walking"
        case .explore: "Explore"
        }
    }

    var detail: String {
        switch self {
        case .quiet: "Roads and street names with less clutter."
        case .everyday: "Buildings, landmarks, and stations."
        case .walking: "Paths and pedestrian connections."
        case .explore: "More shops, cafés, and place labels."
        }
    }

    func url(isDark: Bool) -> URL {
        let appearance = isDark ? "dark" : "light"
        guard let url = Bundle.main.url(forResource: "harta-\(rawValue)-\(appearance)", withExtension: "json") else {
            preconditionFailure("Missing bundled map style: \(rawValue)-\(appearance)")
        }
        return url
    }
}
