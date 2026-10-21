import Foundation

struct PlaceSearchRequest: Equatable, Sendable {
    enum Area: Sendable { case automatic, currentLocation, map }
    var destination: String
    var locality: String?
    var area: Area = .automatic

    var query: String { [destination, locality].compactMap { $0 }.joined(separator: " ") }

    init(destination: String, locality: String? = nil, area: Area = .automatic) {
        self.destination = destination
        self.locality = locality
        self.area = area
    }

    /// Shared by typed and spoken search. Relative areas never become geocoder text.
    init(text: String) {
        var text = text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        self.init(destination: text)
        let suffixes: [(String, Area)] = [
            (" near my current location", .currentLocation), (" near my location", .currentLocation),
            (" close to me", .currentLocation), (" around here", .currentLocation), (" around me", .currentLocation), (" near me", .currentLocation),
            (" near here", .currentLocation), (" nearby", .currentLocation),
            (" in this area", .map), (" on the map", .map), (" near the map center", .map)
        ]
        if let suffix = suffixes.first(where: { text.lowercased().hasSuffix($0.0) }) {
            text = String(text.dropLast(suffix.0.count))
            area = suffix.1
        }
        if text.lowercased().hasPrefix("nearby ") {
            text = String(text.dropFirst(7)); area = .currentLocation
        }
        for separator in [" in ", " near "] {
            if let range = text.range(of: separator, options: [.caseInsensitive, .backwards]) {
                locality = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                text = String(text[..<range.lowerBound])
                break
            }
        }
        destination = text.trimmingCharacters(in: .whitespaces)
    }
}
