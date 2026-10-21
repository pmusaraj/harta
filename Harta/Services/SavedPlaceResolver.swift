import Foundation

struct SavedPlaceResolver {
    enum Resolution: Equatable {
        case matches([Place])
        case missingAlias(String)
        case search(String)
    }

    static func resolve(_ command: VoiceCommand, places: [Place]) -> Resolution {
        let query = VoiceCommand.normalized(command.destination)
        // A locality-qualified request goes to geocoding, never an unrelated local bookmark.
        if let locality = command.locality, !VoiceCommand.normalized(locality).isEmpty {
            return .search(command.searchQuery)
        }
        if let alias = command.savedAlias {
            let matches = places.filter {
                $0.icon == alias || VoiceCommand.normalized($0.name) == alias.rawValue
            }
            return matches.isEmpty ? .missingAlias(alias.title) : .matches(matches)
        }
        guard command.area == .automatic, PlaceSearchRanking.category(for: command.destination) == nil else { return .search(command.searchQuery) }
        let exact = places.filter { VoiceCommand.normalized($0.name) == query }
        if !exact.isEmpty { return .matches(exact) }
        // Partial, fuzzy and category matches belong in the combined results list.
        return .search(command.searchQuery)
    }
}
