import Combine
import CoreLocation
@preconcurrency import FerrostarCore
import FerrostarCoreFFI
import Observation
import UIKit

@MainActor @Observable
final class NavigationModel {
    let destination: Place
    let mode: TravelMode
    let map = MapModel()
    let directions = DirectionsModel()
    private(set) var state: NavigationState?
    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var isPreparing = true
    private(set) var arrived = false
    private(set) var isMuted: Bool
    @ObservationIgnored private let preferences: UserDefaults
    private(set) var errorMessage: String?
    private(set) var gpsMessage: String?
    var followsLocation = true
    @ObservationIgnored private var core: FerrostarCore?
    @ObservationIgnored private var provider: NavigationLocationProvider?
    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []
    @ObservationIgnored private var routeTask: Task<Void, Never>?
    @ObservationIgnored private var watchdog: Task<Void, Never>?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var requestingRoute = false
    @ObservationIgnored private var lastFixAt: Date?
    @ObservationIgnored private var previousIdleTimerDisabled = false
    @ObservationIgnored private var ownsIdleTimer = false

    init(destination: Place, mode: TravelMode, preferences: UserDefaults = .standard) {
        self.destination = destination
        self.mode = mode
        self.preferences = preferences
        isMuted = !preferences.bool(forKey: "navigationVoiceEnabled")
    }

    var instruction: String {
        if arrived { return "You’ve arrived" }
        if isPreparing { return requestingRoute ? "Preparing your route…" : "Finding your location…" }
        return state?.currentVisualInstruction?.primaryContent.text ?? state?.currentStep?.instruction ?? "Follow the route"
    }
    var maneuverSymbol: String {
        if arrived { return "flag.checkered" }
        switch state?.currentVisualInstruction?.primaryContent.maneuverModifier {
        case .left, .sharpLeft: return "arrow.turn.up.left"
        case .right, .sharpRight: return "arrow.turn.up.right"
        case .slightLeft: return "arrow.up.left"
        case .slightRight: return "arrow.up.right"
        case .uTurn: return "arrow.uturn.down"
        default: return "arrow.up"
        }
    }
    var turnDistance: String? { state?.currentProgress.map { Self.distance($0.distanceToNextManeuver) } }
    var remaining: String? {
        guard let progress = state?.currentProgress,
              progress.durationRemaining.isFinite, progress.durationRemaining >= 0 else { return nil }
        let minutes = max(1, ceil(progress.durationRemaining / 60)).formatted(.number.precision(.fractionLength(0)))
        return "\(minutes) min · \(Self.distance(progress.distanceRemaining))"
    }
    var rerouting: Bool { state?.isCalculatingNewRoute == true }
    var offRoute: Bool {
        guard let deviation = state?.currentDeviation else { return false }
        if case .deviation = deviation { return true }
        return false
    }
    static func distance(_ meters: Double) -> String {
        guard meters.isFinite else { return "—" }
        if meters < 1000 { return "\(max(0, meters).rounded().formatted(.number.precision(.fractionLength(0)))) m" }
        return "\((meters / 1000).formatted(.number.precision(.fractionLength(1)))) km"
    }

    func start() {
        stop()
        isPreparing = true; arrived = false; errorMessage = nil; gpsMessage = nil
        lastFixAt = nil; state = nil; followsLocation = true
        map.focus(on: destination)
        let token = generation
        let location = NavigationLocationProvider(mode: mode)
        provider = location
        location.onError = { [weak self] message in
            guard let self, token == self.generation else { return }
            self.gpsMessage = message
        }
        location.onLocation = { [weak self] fix in
            guard let self, token == self.generation else { return }
            self.lastFixAt = Date(); self.gpsMessage = nil
            self.coordinate = fix.coordinates.clLocationCoordinate2D
            if self.core == nil && !self.requestingRoute { self.prepare(from: fix, token: token) }
        }
        location.startUpdating()
        watchdog = Task { [weak self] in
            let started = Date()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                guard let self, self.generation == token else { return }
                if Date().timeIntervalSince(self.lastFixAt ?? started) > 20 {
                    self.gpsMessage = "Waiting for a precise GPS signal. Guidance will resume when your position is available."
                    self.core?.spokenInstructionObserver.stopAndClearQueue()
                }
            }
        }
    }
    private func prepare(from fix: UserLocation, token: UUID) {
        guard let provider else { return }
        requestingRoute = true
        routeTask = Task { [weak self] in
            guard let self else { return }
            do {
                let network = NavigationNetwork { [weak self] in
                    guard let self, self.generation == token else { return }
                    self.errorMessage = "Couldn’t update the route. Check your connection and retry."
                }
                let engine = try FerrostarCore(
                    wellKnownRouteProvider: .valhalla(endpointUrl: AppConfiguration.routingEndpoint.absoluteString,
                                                     profile: mode.rawValue, optionsJson: nil)
                        .withJsonOptions(options: ["language": "en-US", "units": "kilometers"]),
                    locationProvider: provider,
                    navigationControllerConfig: Self.configuration(mode: mode), networkSession: network,
                    spokenInstructionObserver: .initAVSpeechSynthesizer(isMuted: isMuted))
                engine.minimumTimeBeforeRecalculation = 15
                engine.minimumMovementBeforeRecalculation = 15
                let waypoint = Waypoint(coordinate: GeographicCoordinate(lat: destination.latitude, lng: destination.longitude), kind: .break)
                let routes = try await engine.getRoutes(initialLocation: fix, waypoints: [waypoint])
                try Task.checkCancellation()
                guard token == generation else { return }
                guard let route = routes.first else { throw URLError(.cannotParseResponse) }
                core = engine
                if engine.spokenInstructionObserver.isMuted != isMuted {
                    engine.spokenInstructionObserver.toggleMute()
                }
                observe(engine, token: token)
                try engine.startNavigation(route: route, userLocation: provider.lastLocation ?? fix)
                requestingRoute = false; isPreparing = false; errorMessage = nil
                previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
                ownsIdleTimer = true
                UIApplication.shared.isIdleTimerDisabled = true
            } catch {
                guard token == generation, !Task.isCancelled else { return }
                requestingRoute = false; isPreparing = false
                errorMessage = "Navigation couldn’t start. Check your connection and location, then retry."
                provider.stopUpdating()
            }
        }
    }
    private func observe(_ engine: FerrostarCore, token: UUID) {
        engine.$state.receive(on: DispatchQueue.main).sink { [weak self] state in
            // Ferrostar publishes navigation state on the main queue.
            MainActor.assumeIsolated {
                guard let self, self.generation == token, let state else { return }
                self.state = state
                if let fix = state.preferredUserLocation {
                    self.coordinate = fix.coordinates.clLocationCoordinate2D
                    if self.followsLocation { self.map.locate(fix.coordinates.clLocationCoordinate2D) }
                }
                if case .complete = state.tripState {
                    self.arrived = true
                    self.finishTracking()
                }
                if !self.offRoute && !self.rerouting { self.errorMessage = nil }
            }
        }.store(in: &subscriptions)
        engine.$route.receive(on: DispatchQueue.main).sink { [weak self] route in
            MainActor.assumeIsolated {
                guard let self, self.generation == token, let route else { return }
                self.directions.showNavigationGeometry(route.geometry.map { .init(latitude: $0.lat, longitude: $0.lng) })
                self.errorMessage = nil
            }
        }.store(in: &subscriptions)
    }
    static func configuration(mode: TravelMode) -> SwiftNavigationControllerConfig {
        SwiftNavigationControllerConfig(
            waypointAdvance: .waypointWithinRange(20),
            stepAdvanceCondition: stepAdvanceDistanceEntryAndExit(distanceToEndOfStep: mode == .driving ? 30 : 15,
                                                                distanceAfterEndOfStep: 5, minimumHorizontalAccuracy: 30),
            arrivalStepAdvanceCondition: stepAdvanceDistanceToEndOfStep(distance: 15, minimumHorizontalAccuracy: 25),
            routeDeviationTracking: .staticThreshold(minimumHorizontalAccuracy: 30, maxAcceptableDeviation: 40),
            snappedLocationCourseFiltering: .snapToRoute)
    }
    func toggleMute() {
        isMuted.toggle()
        preferences.set(!isMuted, forKey: "navigationVoiceEnabled")
        core?.spokenInstructionObserver.toggleMute()
    }
    func recenter() { followsLocation = true; if let coordinate { map.locate(coordinate) } }
    private func finishTracking() {
        watchdog?.cancel(); watchdog = nil
        provider?.stopUpdating()
        core?.spokenInstructionObserver.stopAndClearQueue()
        gpsMessage = nil
        if ownsIdleTimer { UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled; ownsIdleTimer = false }
    }
    func stop() {
        generation = UUID()
        routeTask?.cancel(); routeTask = nil
        subscriptions.removeAll()
        core?.stopNavigation(); core = nil
        finishTracking()
        provider = nil; requestingRoute = false
    }
}
