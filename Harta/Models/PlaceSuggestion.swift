import Foundation

/// Autocomplete v2 deliberately omits coordinates. Resolve only the selected GID.
struct PlaceSuggestion: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let address: String
}
