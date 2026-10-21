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

    @Test func legacyPlacesDefaultToBookmarkAndIconChangesSurviveRelaunch() throws {
        let directory = URL.temporaryDirectory.appending(path: "Saved Icons \(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appending(path: "places.json")
        let legacy = Data(#"[{"id":"test","name":"Test","address":"","latitude":43,"longitude":-79}]"#.utf8)
        try legacy.write(to: file)
        let store = SavedPlacesStore(fileURL: file)
        #expect(store.icon(for: place) == .bookmark)
        #expect(store.setIcon(.home, for: place))

        let restored = SavedPlacesStore(fileURL: file)
        // A fresh search result has no icon metadata; resolve customization by place ID.
        #expect(restored.icon(for: place) == .home)
        #expect(restored.places.first?.name == place.name)
        #expect(restored.places.first?.latitude == place.latitude)
        #expect(restored.setIcon(.bookmark, for: place))
        #expect(SavedPlacesStore(fileURL: file).icon(for: place) == .bookmark)
    }

    @Test func unknownIconFallsBackWithoutLosingThePlace() throws {
        let data = Data(#"{"id":"test","name":"Test","address":"","latitude":43,"longitude":-79,"savedIcon":"future-icon"}"#.utf8)
        let decoded = try JSONDecoder().decode(Place.self, from: data)
        #expect(decoded.icon == .bookmark)
        #expect(decoded.id == place.id)
    }

    @Test func failedIconWriteKeepsPreviousSelection() throws {
        let directory = URL.temporaryDirectory.appending(path: "Saved Icons \(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "places.json")
        let store = SavedPlacesStore(fileURL: file)
        store.toggle(place)
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)

        #expect(!store.setIcon(.home, for: place))
        #expect(store.icon(for: place) == .bookmark)
        #expect(store.errorMessage != nil)
    }
}
