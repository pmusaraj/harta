import Foundation
import Testing
@testable import Harta

@MainActor
struct CombinedSearchTests {
    let saved = Place(id: "saved", name: "Riverside Club", address: "Montreal", latitude: 45.5, longitude: -73.57, savedIcon: "tennis")
    let gps = LocationFix(latitude: 45.5, longitude: -73.57)

    @Test func showsSavedImmediatelyAndKeepsThemWhenOffline() async {
        let service = CombinedSearchService(fails: true)
        let model = SearchModel(service: service)
        model.query = "tennis courts"
        let task = model.submit(latitude: 0, longitude: 0, currentLocation: gps, savedPlaces: [saved])
        #expect(model.results == [saved])
        #expect(model.isSearching)
        await task?.value
        #expect(model.results == [saved])
        #expect(model.errorMessage != nil)
    }

    @Test func typedAndVoiceSearchUseGPSAndCleanNearMe() async {
        let service = CombinedSearchService()
        let model = SearchModel(service: service)
        model.query = "tennis near me"
        await model.submit(latitude: 0, longitude: 0, currentLocation: gps, savedPlaces: [saved])?.value
        #expect(await service.requests.first?.query == "tennis")
        #expect(await service.requests.first?.latitude == gps.latitude)
        #expect(model.results == [saved])
        let command = try? BasicVoiceCommandParser.parse("Find tennis near me")
        await model.submit(request: command?.searchRequest, latitude: 0, longitude: 0, currentLocation: gps, savedPlaces: [saved])?.value
        #expect(await service.requests.last?.latitude == gps.latitude)
    }

    @Test func defaultsToGPSButExplicitMapAreaUsesMapCenter() async {
        let service = CombinedSearchService()
        let model = SearchModel(service: service)
        model.query = "tennis"
        await model.submit(latitude: 10, longitude: 20, currentLocation: gps)?.value
        #expect(await service.requests.last?.latitude == gps.latitude)
        model.query = "tennis in this area"
        await model.submit(latitude: 10, longitude: 20, currentLocation: gps)?.value
        #expect(await service.requests.last?.latitude == 10)
        #expect(await service.requests.last?.query == "tennis")
    }

    @Test func namedLocalityOmitsGPSBiasAndIncludesMatchingSavedPlaces() async {
        let service = CombinedSearchService()
        let model = SearchModel(service: service)
        model.query = "tennis in Montreal"
        await model.submit(latitude: 10, longitude: 20, currentLocation: gps, savedPlaces: [saved])?.value
        #expect(await service.requests.last?.latitude == nil)
        #expect(await service.requests.last?.longitude == nil)
        #expect(model.results == [saved])
    }

    @Test func explicitNearMeRequiresFreshGPSWhileAutomaticSearchExplainsMapFallback() async {
        let service = CombinedSearchService()
        let model = SearchModel(service: service)
        let stale = LocationFix(timestamp: .now.addingTimeInterval(-600), latitude: 45, longitude: -73)
        model.query = "tennis near me"
        await model.submit(latitude: 10, longitude: 20, currentLocation: stale)?.value
        #expect(model.needsLocation)
        #expect(await service.requests.isEmpty)
        model.query = "tennis"
        await model.submit(latitude: 10, longitude: 20, currentLocation: stale)?.value
        #expect(!model.needsLocation)
        #expect(model.locationMessage != nil)
        #expect(await service.requests.last?.latitude == 10)
    }

    @Test func mergesOnlineResultsAndRejectsStaleCompletion() async {
        let service = ControlledSearchService()
        let model = SearchModel(service: service)
        model.query = "tennis"
        let task = model.submit(latitude: 45, longitude: -73, savedPlaces: [saved])
        while !(await service.hasPendingRequest) { await Task.yield() }
        #expect(model.results == [saved])
        model.queryChanged()
        await service.finish()
        await task?.value
        #expect(model.results.isEmpty)
    }
}
