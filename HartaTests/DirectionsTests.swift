import Foundation
import Testing
@testable import Harta

@MainActor
struct DirectionsTests {
    @Test(arguments: ["1e300", "-1", "5.5340232221128655e20"])
    func rejectsUnsafeRouteDurations(_ duration: String) throws {
        let json = """
        {"trip":{"status":0,"summary":{"time":\(duration),"length":1},"legs":[{"shape":"_izlhA~rlgdF_{geC~ywl@_kwzCn`{nI","maneuvers":[]}]}}
        """
        let response = try JSONDecoder().decode(ValhallaResponse.self, from: Data(json.utf8))
        #expect(throws: (any Error).self) { try response.route() }
    }

    @Test(arguments: ["1e300", "-1", "9223372036854776"])
    func rejectsUnsafeManeuverDistances(_ distance: String) throws {
        let json = """
        {"trip":{"status":0,"summary":{"time":60,"length":1},"legs":[{"shape":"_izlhA~rlgdF_{geC~ywl@_kwzCn`{nI","maneuvers":[{"instruction":"Go","length":\(distance),"begin_shape_index":0,"end_shape_index":2}]}]}}
        """
        let response = try JSONDecoder().decode(ValhallaResponse.self, from: Data(json.utf8))
        #expect(throws: (any Error).self) { try response.route() }
    }

    @Test func decodesPolyline6AndRejectsTruncation() throws {
        let points = try ValhallaResponse.decodePolyline("_izlhA~rlgdF_{geC~ywl@_kwzCn`{nI")
        #expect(points.count == 3)
        #expect(abs(points[0].latitude - 38.5) < 0.000001)
        #expect(abs(points[2].longitude + 126.453) < 0.000001)
        #expect(throws: (any Error).self) { try ValhallaResponse.decodePolyline("_izlhA~") }
    }
    @Test func validatesStepIndicesAndSummary() throws {
        let json = #"{"trip":{"status":0,"summary":{"time":123,"length":1.5},"legs":[{"shape":"_izlhA~rlgdF_{geC~ywl@_kwzCn`{nI","maneuvers":[{"instruction":"Go north","length":1.5,"begin_shape_index":0,"end_shape_index":2}]}]}}"#
        let response = try JSONDecoder().decode(ValhallaResponse.self, from: Data(json.utf8))
        let route = try response.route()
        #expect(route.seconds == 123)
        #expect(route.steps.first?.end == 2)
        let invalid = json.replacingOccurrences(of: "\"end_shape_index\":2", with: "\"end_shape_index\":3")
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(ValhallaResponse.self, from: Data(invalid.utf8)).route()
        }
    }
    @Test(.timeLimit(.minutes(1))) func discardsCanceledRoute() async {
        let service = ControlledRouteService()
        let model = DirectionsModel(service: service)
        let place = Place(id: "test", name: "Test", address: "", latitude: 43, longitude: -79)
        model.origin = place
        let task = model.calculate(to: place)
        while !(await service.hasPendingRequest) { await Task.yield() }
        model.clear()
        await service.finish()
        await task?.value
        #expect(model.route == nil)
        #expect(!model.isLoading)
    }
    @Test(.timeLimit(.minutes(1))) func publishesRouteAndClearsSelectedStep() async {
        let service = ControlledRouteService()
        let model = DirectionsModel(service: service)
        let place = Place(id: "test", name: "Test", address: "", latitude: 43, longitude: -79)
        model.origin = place
        let task = model.calculate(to: place)
        while !(await service.hasPendingRequest) { await Task.yield() }
        await service.finish()
        await task?.value
        #expect(model.route?.kilometers == 1)
        #expect(!model.isLoading)
        model.select(model.route?.steps.first)
        model.clear()
        #expect(model.selectedStep == nil)
    }
}
