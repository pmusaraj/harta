import Foundation

enum TransitKind: String, CaseIterable {
    case bus, metro, rail, tram, ferry

    var imageName: String { "harta-transit-\(rawValue)" }
    var symbol: String {
        switch self {
        case .bus: "bus.fill"
        case .metro: "m.circle.fill"
        case .rail: "train.side.front.car"
        case .tram: "tram.fill"
        case .ferry: "ferry.fill"
        }
    }
    static func from(subclass: String) -> TransitKind? {
        switch subclass {
        case "bus_stop", "bus_station": .bus
        case "subway", "subway_entrance": .metro
        case "station", "halt", "train_station_entrance": .rail
        case "tram_stop": .tram
        case "ferry_terminal": .ferry
        default: nil
        }
    }
    var title: String {
        switch self {
        case .bus: "Bus stop / station"
        case .metro: "Metro / subway"
        case .rail: "Rail station"
        case .tram: "Tram stop"
        case .ferry: "Ferry terminal"
        }
    }
}
