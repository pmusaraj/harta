import Foundation

enum AppConfiguration {
    static let routingEndpoint = url("https://api.stadiamaps.com/route/v1")
    static let routingCredit = url("https://stadiamaps.com/")
    static let searchEndpoint = url("https://api.stadiamaps.com/geocoding/v2")
    static let osmCredit = url("https://www.openstreetmap.org/copyright")
    static let tilesCredit = url("https://openmaptiles.org/")
    static let mapsCredit = url("https://openfreemap.org/")
    static let mapLibreCredit = url("https://github.com/maplibre/maplibre-native/blob/main/LICENSE.md")
    static let searchCredit = url("https://stadiamaps.com/attribution/")

    static var stadiaAPIKey: String {
        let value = (Bundle.main.object(forInfoDictionaryKey: "StadiaMapsAPIKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.hasPrefix("$(") ? "" : value
    }

    static func authenticate(_ request: inout URLRequest) throws {
        guard !stadiaAPIKey.isEmpty else { throw StadiaServiceError.missingKey }
        request.setValue("Stadia-Auth \(stadiaAPIKey)", forHTTPHeaderField: "Authorization")
    }

    static func url(_ value: String) -> URL {
        guard let url = URL(string: value) else {
            preconditionFailure("Invalid built-in URL: \(value)")
        }
        return url
    }
}
