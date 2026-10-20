import Foundation
import Observation

@MainActor @Observable
final class DirectionsModel {
    var origin: Place?
    var mode: TravelMode = .walking { didSet { preferences.set(mode.rawValue, forKey: "travelMode") } }
    private let preferences: UserDefaults
    private(set) var route: MapRoute?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var selectedStep: MapRoute.Step?
    var cameraRequest = UUID()
    private let service: any RouteProviding
    private var task: Task<Void, Never>?
    private var generation = UUID()
    init(service: any RouteProviding = ValhallaRoutingService(), preferences: UserDefaults = .standard) {
        self.service = service
        self.preferences = preferences
        self.mode = TravelMode(rawValue: preferences.string(forKey: "travelMode") ?? "") ?? .walking
    }
    func clear() {
        task?.cancel(); generation = UUID(); isLoading = false
        route = nil; selectedStep = nil; errorMessage = nil
    }
    @discardableResult func calculate(to destination: Place) -> Task<Void, Never>? {
        clear()
        guard let origin else { return nil }
        isLoading = true
        let token = generation
        let mode = mode
        task = Task {
            do {
                let result = try await service.route(from: origin, to: destination, mode: mode)
                guard !Task.isCancelled, token == generation else { return }
                route = result; cameraRequest = UUID(); isLoading = false
            } catch {
                guard !Task.isCancelled, token == generation else { return }
                isLoading = false
                errorMessage = "Couldn’t find a route. Check your connection or try another starting point or travel mode."
            }
        }
        return task
    }
    func showNavigationGeometry(_ points: [MapRoute.Point]) {
        route = MapRoute(points: points, steps: [], seconds: 0, kilometers: 0)
        selectedStep = nil
    }
    func select(_ step: MapRoute.Step?) { selectedStep = step; cameraRequest = UUID() }
}
