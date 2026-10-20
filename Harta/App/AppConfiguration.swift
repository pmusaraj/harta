import Foundation

enum AppConfiguration {
    static let routingEndpoint = url("https://valhalla1.openstreetmap.de/route")
    static let routingCredit = url("https://valhalla.openstreetmap.de/")
    static let searchEndpoint = url("https://photon.komoot.io/api/")
    static let osmCredit = url("https://www.openstreetmap.org/copyright")
    static let tilesCredit = url("https://openmaptiles.org/")
    static let mapsCredit = url("https://openfreemap.org/")
    static let mapLibreCredit = url("https://github.com/maplibre/maplibre-native/blob/main/LICENSE.md")
    static let searchCredit = url("https://github.com/komoot/photon")

    static func url(_ value: String) -> URL {
        guard let url = URL(string: value) else {
            preconditionFailure("Invalid built-in URL: \(value)")
        }
        return url
    }
}
