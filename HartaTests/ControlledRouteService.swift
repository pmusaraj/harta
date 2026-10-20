import Foundation
@testable import Harta

actor ControlledRouteService: RouteProviding {
    private var continuation: CheckedContinuation<MapRoute, Never>?
    var hasPendingRequest: Bool { continuation != nil }
    func route(from origin: Place, to destination: Place, mode: TravelMode) async throws -> MapRoute {
        await withCheckedContinuation { continuation = $0 }
    }
    func finish() {
        continuation?.resume(returning: MapRoute(points: [.init(latitude: 43, longitude: -79), .init(latitude: 43.01, longitude: -79)],
            steps: [.init(id: 0, instruction: "Go north", kilometers: 1, start: 0, end: 1)], seconds: 600, kilometers: 1))
        continuation = nil
    }
}
