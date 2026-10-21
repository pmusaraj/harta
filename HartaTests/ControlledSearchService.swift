import Foundation
@testable import Harta

actor ControlledSearchService: PlaceSearching {
    private var continuation: CheckedContinuation<[Place], Never>?
    var hasPendingRequest: Bool { continuation != nil }

    func search(query: String, latitude: Double?, longitude: Double?) async throws -> [Place] {
        await withCheckedContinuation { continuation = $0 }
    }

    func finish() {
        continuation?.resume(returning: [Place(id: "toronto", name: "Toronto", address: "Canada", latitude: 43, longitude: -79)])
        continuation = nil
    }
}
