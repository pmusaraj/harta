import Foundation

// Stable bit values keep saved selections compatible when categories are added.
enum MapOverlay: Int, CaseIterable, Identifiable {
    case chargers = 1, toilets = 2, parking = 4, cycling = 8, transit = 16, essentials = 32

    static let preferenceKey = "mapOverlays"
    var id: Int { rawValue }
    var key: String {
        switch self {
        case .chargers: "chargers"
        case .toilets: "toilets"
        case .parking: "parking"
        case .cycling: "cycling"
        case .transit: "transit"
        case .essentials: "essentials"
        }
    }
    var layerIdentifier: String { "harta-overlay-\(key)" }
    var title: String {
        switch self {
        case .chargers: "EV chargers"
        case .toilets: "Toilets"
        case .parking: "Parking"
        case .cycling: "Cycling paths"
        case .transit: "Transit"
        case .essentials: "Everyday essentials"
        }
    }
    var detail: String {
        switch self {
        case .chargers: "Charging locations, without live availability."
        case .toilets: "Mapped toilets; access and opening hours vary."
        case .parking: "Car parks and parking entrances."
        case .cycling: "Cycleways and shared paths designated for cycling."
        case .transit: "Blue bus markers, purple metro markers, and distinct rail and ferry symbols."
        case .essentials: "Groceries, convenience stores, pharmacies, and ATMs."
        }
    }
    var symbol: String {
        switch self {
        case .chargers: "bolt.car"
        case .toilets: "toilet"
        case .parking: "parkingsign"
        case .cycling: "bicycle"
        case .transit: "tram"
        case .essentials: "basket"
        }
    }
    func isEnabled(in selection: Int) -> Bool { selection & rawValue != 0 }
    static func enabledCount(in selection: Int) -> Int {
        allCases.filter { $0.isEnabled(in: selection) }.count
    }
}
