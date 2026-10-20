import Foundation
import Testing
@testable import Harta

@MainActor
struct RecentPlacesTests {
    @Test func deduplicatesBoundsAndRestoresHistory() throws {
        let suite = "harta-tests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RecentPlacesStore(defaults: defaults)
        for index in 0..<12 {
            store.record(Place(id: "\(index)", name: "Place \(index)", address: "", latitude: 43, longitude: -79))
        }
        #expect(store.places.count == 10)
        let older = store.places[5]
        store.record(older)
        #expect(store.places.first == older)
        #expect(store.places.count == 10)
        #expect(RecentPlacesStore(defaults: defaults).places == store.places)
        store.clear()
        #expect(RecentPlacesStore(defaults: defaults).places.isEmpty)
    }
    @Test func remembersTravelMode() throws {
        let suite = "harta-tests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = DirectionsModel(preferences: defaults)
        #expect(model.mode == .walking)
        model.mode = .cycling
        #expect(DirectionsModel(preferences: defaults).mode == .cycling)
    }
}
