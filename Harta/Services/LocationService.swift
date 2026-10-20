import CoreLocation
import Observation

@MainActor @Observable
final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private(set) var isLocating = false
    private(set) var fix: LocationFix?
    var errorMessage: String?
    private var tracksContinuously = false
    private var running = false
    private var lastTimestamp: Date?
    private var timeout: Task<Void, Never>?

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
    }

    func startTracking(requestPermission: Bool = false) {
        tracksContinuously = true
        // Scene activation can follow the first fix without tracking ever stopping.
        guard !running else { return }
        if requestPermission { locate() } else { locateIfAuthorized() }
    }

    func locateIfAuthorized() {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways { locate() }
    }

    func locate() {
        guard !isLocating else { return }
        isLocating = true
        running = true
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: requestLocation()
        case .denied, .restricted: deny()
        @unknown default: deny()
        }
    }

    func stop() {
        running = false
        manager.stopUpdatingLocation()
        timeout?.cancel()
        timeout = nil
        isLocating = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard running else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: requestLocation()
        case .denied, .restricted: deny()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard running,
              let location = locations.filter({ Self.isUsable($0) }).max(by: { $0.timestamp < $1.timestamp }),
              lastTimestamp.map({ location.timestamp > $0 }) ?? true else { return }
        lastTimestamp = location.timestamp
        fix = LocationFix(timestamp: location.timestamp, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        errorMessage = nil
        isLocating = false
        timeout?.cancel()
        timeout = nil
        if !tracksContinuously { stop() }
    }

    static func isUsable(_ location: CLLocation, now: Date = Date()) -> Bool {
        CLLocationCoordinate2DIsValid(location.coordinate)
            && location.horizontalAccuracy >= 0
            && location.timestamp.timeIntervalSince(now) <= 1
            && now.timeIntervalSince(location.timestamp) <= 15
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard running else { return }
        // A temporary loss of GPS should not end foreground tracking.
        if (error as? CLError)?.code == .locationUnknown { return }
        stop()
        errorMessage = "Your location couldn’t be found. Please try again."
    }

    private func requestLocation() {
        // Continuous updates also allow a poor initial fix to improve immediately.
        manager.startUpdatingLocation()
        timeout?.cancel()
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(15)) } catch { return }
            guard let self, self.isLocating else { return }
            if self.tracksContinuously { self.isLocating = false } else { self.stop() }
            self.errorMessage = "Finding your location took too long. Please try again."
        }
    }

    private func deny() {
        stop()
        errorMessage = "Location access is off. You can enable it for Harta in Settings, or keep browsing without it."
    }
}
