import CoreLocation
import Testing
@testable import Harta

@MainActor
struct LocationServiceTests {
    private func location(_ latitude: Double, at date: Date = Date()) -> CLLocation {
        CLLocation(coordinate: .init(latitude: latitude, longitude: -73), altitude: 0,
                   horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: date)
    }

    @Test func trackingContinuesAfterFirstFixAndStopsInBackground() {
        let manager = TestLocationManager()
        let service = LocationService(manager: manager)
        service.startTracking()
        let first = location(45, at: Date().addingTimeInterval(-2))
        service.locationManager(manager, didUpdateLocations: [first])
        #expect(!service.isLocating)
        #expect(manager.stops == 0)
        let second = location(46)
        service.locationManager(manager, didUpdateLocations: [second])
        #expect(service.fix?.latitude == 46)
        #expect(service.fix?.timestamp == second.timestamp)
        service.locationManager(manager, didUpdateLocations: [first])
        #expect(service.fix?.latitude == 46)
        service.stop()
        service.locationManager(manager, didUpdateLocations: [location(47)])
        #expect(service.fix?.latitude == 46)
        service.startTracking()
        #expect(manager.starts == 2)
        service.stop()
    }

    @Test func temporaryFailureKeepsTrackingButOneShotStopsAfterFix() {
        let manager = TestLocationManager()
        let service = LocationService(manager: manager)
        service.startTracking()
        service.locationManager(manager, didFailWithError: CLError(.locationUnknown))
        #expect(manager.stops == 0)
        service.locationManager(manager, didUpdateLocations: [location(45)])
        #expect(service.fix != nil)
        service.stop()
        let oneShot = LocationService(manager: manager)
        oneShot.locate()
        oneShot.locationManager(manager, didUpdateLocations: [location(46)])
        #expect(!oneShot.isLocating)
        #expect(manager.stops == 2)
    }

    @Test func becomingActiveAfterFirstFixDoesNotRestartLocationWait() {
        let manager = TestLocationManager()
        let service = LocationService(manager: manager)
        service.startTracking(requestPermission: true)
        service.locationManager(manager, didUpdateLocations: [location(45)])

        // Becoming active after startup or a system prompt must keep the existing session.
        service.startTracking()

        #expect(manager.starts == 1)
        #expect(!service.isLocating)
        #expect(service.errorMessage == nil)
        service.stop()
    }

    @Test func rejectsStaleFutureAndInvalidFixes() {
        let now = Date()
        #expect(LocationService.isUsable(location(45, at: now), now: now))
        #expect(!LocationService.isUsable(location(45, at: now.addingTimeInterval(-20)), now: now))
        #expect(!LocationService.isUsable(location(45, at: now.addingTimeInterval(10)), now: now))
        #expect(!LocationService.isUsable(location(100, at: now), now: now))
    }
}
