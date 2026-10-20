import Foundation
import Testing
@testable import Harta

@MainActor
struct SavedPlacesStoreTests {
    private let place = Place(id: "test", name: "Test", address: "", latitude: 43, longitude: -79)

    @Test func savesAndRemovesAcrossLaunches() throws {
        let directory = URL.temporaryDirectory.appending(path: "Saved Places \(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "places.json")
        let store = SavedPlacesStore(fileURL: file)
        store.toggle(place)
        #expect(store.errorMessage == nil)
        let restored = SavedPlacesStore(fileURL: file)
        #expect(restored.places == [place])
        restored.remove(ids: [place.id])
        #expect(SavedPlacesStore(fileURL: file).places.isEmpty)
    }

    @Test func preservesCorruptData() throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let original = Data("not valid JSON".utf8)
        try original.write(to: file)
        let store = SavedPlacesStore(fileURL: file)
        #expect(store.errorMessage != nil)
        store.toggle(place)
        #expect(try Data(contentsOf: file) == original)
        #expect(store.places.isEmpty)
    }
}
