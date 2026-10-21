import Foundation

struct VoiceCommand: Equatable, Sendable {
    enum Action: Sendable { case search, directions }
    var action: Action = .search
    var destination: String
    var locality: String?
    var mode: TravelMode?
    var area: PlaceSearchRequest.Area = .automatic

    var searchRequest: PlaceSearchRequest {
        PlaceSearchRequest(destination: destination, locality: locality, area: area)
    }

    var searchQuery: String {
        [destination, locality].compactMap { $0 }.joined(separator: " ")
    }

    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: " ")
    }

    var savedAlias: SavedPlaceIcon? {
        switch Self.normalized(destination) {
        case "home", "my home": .home
        case "work", "my work": .work
        default: nil
        }
    }
}
