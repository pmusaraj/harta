import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import Testing
@testable import Harta

@MainActor
struct NavigationTests {
    @Test func handlesInvalidNavigationDistances() {
        #expect(NavigationModel.distance(.infinity) == "—")
        #expect(NavigationModel.distance(.nan) == "—")
        #expect(NavigationModel.distance(-1) == "0 m")
        #expect(NavigationModel.distance(123) == "123 m")
        #expect(!NavigationModel.distance(1e300).isEmpty)
    }

    @Test func voiceDefaultsMutedAndRemembersBothChoices() throws {
        let suite = "NavigationVoiceTests.\(UUID().uuidString)"
        let preferences = try #require(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let place = Place(id: "voice-test", name: "Destination", address: "", latitude: 43.65, longitude: -79.38)
        let first = NavigationModel(destination: place, mode: .walking, preferences: preferences)
        #expect(first.isMuted)
        first.toggleMute()
        first.stop()
        let next = NavigationModel(destination: place, mode: .driving, preferences: preferences)
        #expect(!next.isMuted)
        next.toggleMute()
        next.stop()
        let restoredPreferences = try #require(UserDefaults(suiteName: suite))
        let last = NavigationModel(destination: place, mode: .cycling, preferences: restoredPreferences)
        #expect(last.isMuted)
    }

    @Test func rejectsStaleAndInaccurateLocations() {
        let now = Date()
        func location(accuracy: Double, age: Double) -> CLLocation {
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 43, longitude: -79), altitude: 0,
                       horizontalAccuracy: accuracy, verticalAccuracy: -1, timestamp: now.addingTimeInterval(-age))
        }
        #expect(NavigationLocationProvider.isUsable(location(accuracy: 5, age: 1), now: now))
        #expect(!NavigationLocationProvider.isUsable(location(accuracy: 5, age: 30), now: now))
        #expect(!NavigationLocationProvider.isUsable(location(accuracy: 100, age: 1), now: now))
        #expect(!NavigationLocationProvider.isUsable(location(accuracy: -1, age: 1), now: now))
    }

    @Test func navigationFixtureHasVisualAndSpokenGuidance() throws {
        let route = try fixture()
        #expect(route.steps.contains { !$0.spokenInstructions.isEmpty })
        #expect(route.steps.contains { !$0.visualInstructions.isEmpty })
        #expect(route.geometry.count > 10)
    }

    @Test(.timeLimit(.minutes(1))) func navigationAdvancesAndStopsWithoutLateRevival() async throws {
        let route = try fixture()
        let start = try #require(route.geometry.first)
        let location = SimulatedLocationProvider(location: fix(start))
        let core = try FerrostarCore(
            wellKnownRouteProvider: .valhalla(endpointUrl: "https://example.invalid/route", profile: "pedestrian", optionsJson: nil),
            locationProvider: location, navigationControllerConfig: NavigationModel.configuration(mode: .walking),
            networkSession: NavigationTestNetwork(), spokenInstructionObserver: .initAVSpeechSynthesizer(isMuted: true))
        try core.startNavigation(route: route, userLocation: fix(start))
        await drainMainQueue()
        #expect(core.state?.isNavigating == true)
        let initialDistance = try #require(core.state?.currentProgress?.distanceRemaining)
        for coordinate in route.geometry.prefix(25) {
            core.locationManager(location, didUpdateLocations: [fix(coordinate)])
            await drainMainQueue()
        }
        let remaining = try #require(core.state?.currentProgress?.distanceRemaining)
        #expect(remaining < initialDistance)
        // Queue one more state change, then stop before it reaches the main queue.
        core.locationManager(location, didUpdateLocations: [fix(start)])
        core.stopNavigation()
        await drainMainQueue()
        #expect(core.state == nil)
        #expect(core.route == nil)
    }

    @Test(.timeLimit(.minutes(1))) func detectsDeviationAndArrival() async throws {
        let route = try fixture()
        let start = try #require(route.geometry.first)
        let location = SimulatedLocationProvider(location: fix(start))
        let core = try FerrostarCore(
            wellKnownRouteProvider: .valhalla(endpointUrl: "https://example.invalid/route", profile: "pedestrian", optionsJson: nil),
            locationProvider: location, navigationControllerConfig: NavigationModel.configuration(mode: .walking),
            networkSession: NavigationTestNetwork(), spokenInstructionObserver: .initAVSpeechSynthesizer(isMuted: true))
        try core.startNavigation(route: route, userLocation: fix(start))
        await drainMainQueue()
        for _ in 0..<3 {
            core.locationManager(location, didUpdateLocations: [fix(.init(lat: start.lat, lng: start.lng + 0.02))])
            await drainMainQueue()
        }
        guard case .deviation = core.state?.currentDeviation else {
            Issue.record("Expected a route deviation away from the route")
            core.stopNavigation()
            return
        }
        // Restart on the route and replay its geometry to arrival.
        core.stopNavigation()
        try core.startNavigation(route: route, userLocation: fix(start))
        await drainMainQueue()
        for coordinate in route.geometry {
            core.locationManager(location, didUpdateLocations: [fix(coordinate)])
            await drainMainQueue()
        }
        if let end = route.geometry.last {
            for _ in 0..<3 {
                core.locationManager(location, didUpdateLocations: [fix(end)])
                await drainMainQueue()
            }
        }
        guard case .complete = core.state?.tripState else {
            Issue.record("Expected arrival after following the route geometry")
            core.stopNavigation()
            return
        }
        core.stopNavigation()
    }

    private func fixture() throws -> Route {
        let url = try #require(Bundle(for: TestResources.self).url(forResource: "navigation-route", withExtension: "json"))
        let adapter = try RouteAdapter.fromWellKnownRouteProvider(wellKnownRouteProvider:
            .valhalla(endpointUrl: "https://example.invalid/route", profile: "pedestrian", optionsJson: nil))
        return try #require(adapter.parseResponse(response: Data(contentsOf: url)).first)
    }
    private func fix(_ coordinate: GeographicCoordinate) -> UserLocation {
        UserLocation(coordinates: coordinate, horizontalAccuracy: 5, courseOverGround: nil, timestamp: Date(), speed: nil)
    }
    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
    }
}
