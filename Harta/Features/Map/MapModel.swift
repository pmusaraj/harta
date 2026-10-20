import CoreLocation
import Foundation
import Observation

@MainActor @Observable
final class MapModel {
    // Montreal is only a fallback while the startup location request completes.
    private(set) var latitude = 45.5019
    private(set) var longitude = -73.5674
    private(set) var zoom = 12.0
    private var requestedStartupLocation = false
    private var centersOnNextLocation = true

    func beginStartupLocation() -> Bool {
        guard !requestedStartupLocation else { return false }
        requestedStartupLocation = true
        return true
    }

    func requestLocationCentering() { centersOnNextLocation = true }
    func stopLocationCentering() { centersOnNextLocation = false }

    func receiveLocation(_ coordinate: CLLocationCoordinate2D) {
        guard centersOnNextLocation else { return }
        centersOnNextLocation = false
        locate(coordinate)
    }

    var selectedPlace: Place?
    private(set) var cameraRequest = UUID()
    var styleReloadRequest = UUID()
    var mapError: String?

    func focus(on place: Place) {
        stopLocationCentering()
        selectedPlace = place
        latitude = place.latitude
        longitude = place.longitude
        zoom = 16
        cameraRequest = UUID()
    }

    func locate(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        zoom = max(zoom, 15)
        cameraRequest = UUID()
    }

    func viewportChanged(center: CLLocationCoordinate2D, zoom: Double) {
        latitude = center.latitude
        longitude = center.longitude
        self.zoom = zoom
    }

    func retryMap() {
        mapError = nil
        styleReloadRequest = UUID()
    }

    func centerPin() -> Place {
        .pin(at: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
}
