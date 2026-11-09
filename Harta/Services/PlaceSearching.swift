import Foundation

import Foundation

protocol PlaceSearching: Sendable {
    func search(query: String, latitude: Double?, longitude: Double?) async throws -> [Place]
    func suggestions(query: String, latitude: Double?, longitude: Double?) async throws -> [PlaceSuggestion]
    func resolve(_ suggestion: PlaceSuggestion) async throws -> Place
}

// Existing injected search providers need no autocomplete implementation.
extension PlaceSearching {
    func suggestions(query: String, latitude: Double?, longitude: Double?) async throws -> [PlaceSuggestion] { [] }
    func resolve(_ suggestion: PlaceSuggestion) async throws -> Place { throw URLError(.unsupportedURL) }
}
