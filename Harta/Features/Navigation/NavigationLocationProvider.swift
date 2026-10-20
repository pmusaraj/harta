import CoreLocation
@preconcurrency import FerrostarCore
import FerrostarCoreFFI

/// Owns high-accuracy GPS only for an explicitly started navigation session.
@MainActor
final class NavigationLocationProvider: NSObject, @preconcurrency LocationProviding, @preconcurrency CLLocationManagerDelegate {
    weak var delegate: (any LocationManagingDelegate)?
    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }
    private(set) var lastLocation: UserLocation?
    var lastHeading: Heading? { nil }
    var onLocation: ((UserLocation) -> Void)?
    var onError: ((String) -> Void)?
    private let manager = CLLocationManager()
    private var running = false

    init(mode: TravelMode) {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 3
        manager.activityType = mode == .driving ? .automotiveNavigation : .fitness
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
    }
    func startUpdating() {
        running = true
        switch authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            guard manager.accuracyAuthorization == .fullAccuracy else {
                onError?("Enable Precise Location for Harta in Settings to start navigation.")
                stopUpdating(); return
            }
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
        default:
            onError?("Enable location access for Harta in Settings to start navigation.")
            stopUpdating()
        }
    }
    func stopUpdating() {
        running = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if running { startUpdating() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard running, let location = locations.last,
              Self.isUsable(location) else { return }
        let fix = location.userLocation
        lastLocation = fix
        onLocation?(fix)
        delegate?.locationManager(self, didUpdateLocations: [fix])
    }
    static func isUsable(_ location: CLLocation, now: Date = Date()) -> Bool {
        location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 50
            && abs(location.timestamp.timeIntervalSince(now)) <= 15
            && CLLocationCoordinate2DIsValid(location.coordinate)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard running else { return }
        onError?("GPS is unavailable. Move to an open area or check Location Services.")
    }
}
