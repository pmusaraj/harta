import CoreLocation
import Testing
@testable import Harta

@MainActor
struct MapStartupTests {
    @Test func startupCentersOnceAndRespectsBrowsing() {
        let model = MapModel()
        #expect(model.beginStartupLocation())
        #expect(!model.beginStartupLocation())
        let montreal = CLLocationCoordinate2D(latitude: 45.5088, longitude: -73.554)
        model.receiveLocation(montreal)
        #expect(model.latitude == montreal.latitude)
        #expect(model.longitude == montreal.longitude)
        #expect(model.zoom == 15)
        model.viewportChanged(center: CLLocationCoordinate2D(latitude: 46, longitude: -74), zoom: 13)
        model.receiveLocation(montreal)
        #expect(model.latitude == 46)
        model.requestLocationCentering()
        model.receiveLocation(montreal)
        #expect(model.latitude == montreal.latitude)
    }

    @Test func lateStartupFixDoesNotOverridePanOrDestination() {
        let model = MapModel()
        model.stopLocationCentering()
        let request = model.cameraRequest
        model.receiveLocation(CLLocationCoordinate2D(latitude: 40, longitude: -70))
        #expect(model.cameraRequest == request)
        model.requestLocationCentering()
        let destination = Place.pin(at: CLLocationCoordinate2D(latitude: 46, longitude: -74))
        model.focus(on: destination)
        model.receiveLocation(CLLocationCoordinate2D(latitude: 40, longitude: -70))
        #expect(model.latitude == 46)
    }

    @Test func transitTypesAreDistinctWithoutGuessingStationMode() {
        #expect(TransitKind.from(subclass: "bus_stop") == .bus)
        #expect(TransitKind.from(subclass: "bus_station") == .bus)
        #expect(TransitKind.from(subclass: "subway_entrance") == .metro)
        #expect(TransitKind.from(subclass: "subway") == .metro)
        #expect(TransitKind.from(subclass: "station") == .rail)
        #expect(TransitKind.from(subclass: "parking") == nil)
        #expect(TransitKind.bus.symbol != TransitKind.metro.symbol)
    }
}
