import CoreLocation

final class TestLocationManager: CLLocationManager {
    var starts = 0
    var stops = 0
    override var authorizationStatus: CLAuthorizationStatus { .authorizedWhenInUse }
    override func startUpdatingLocation() { starts += 1 }
    override func stopUpdatingLocation() { stops += 1 }
}
