import Foundation

protocol PlaceSearching: Sendable {
    func search(query: String, latitude: Double, longitude: Double) async throws -> [Place]
}
