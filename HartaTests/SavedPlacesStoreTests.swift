import Foundation
import Testing
import UIKit
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

    @Test func detectsSportNamesWithoutMatchingAddressOrPartialWords() {
        let examples: [(String, SavedPlaceIcon)] = [
            ("West-End Tennis Club", .tennis), ("SOCCER Centre", .soccer),
            ("Basketball Courts", .basketball), ("American Football Club", .football),
            ("Club de fútbol", .soccer), ("Baseball Park", .baseball),
            ("Hockey Arena", .hockey), ("Golf Club", .golf),
            ("Piscine municipale", .swimming), ("Volleyball Club", .volleyball),
            ("Badminton Club", .badminton), ("Pickleball Courts", .pickleball),
            ("Cricket Ground", .cricket), ("Rugby Club", .rugby)
        ]
        for (name, expected) in examples {
            let venue = Place(id: name, name: name, address: "", latitude: 43, longitude: -79)
            #expect(venue.icon == expected)
        }
        let unrelated = Place(id: "other", name: "Golford Café", address: "1 Tennis Road",
                              latitude: 43, longitude: -79)
        #expect(unrelated.suggestedIcon == nil)
        #expect(unrelated.icon == .bookmark)
        for icon in SavedPlaceIcon.allCases {
            #expect(UIImage(systemName: icon.symbol) != nil)
        }
    }

    @Test func explicitSportOverrideSurvivesRelaunch() {
        let directory = URL.temporaryDirectory.appending(path: "Sport Icons \(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "places.json")
        let venue = Place(id: "tennis", name: "Tennis Club", address: "", latitude: 43, longitude: -79)
        let store = SavedPlacesStore(fileURL: file)
        store.toggle(venue)
        #expect(SavedPlacesStore(fileURL: file).icon(for: venue) == .tennis)
        #expect(store.setIcon(.bookmark, for: venue))
        #expect(SavedPlacesStore(fileURL: file).icon(for: venue) == .bookmark)
        #expect(store.setIcon(.basketball, for: venue))
        #expect(SavedPlacesStore(fileURL: file).icon(for: venue) == .basketball)
    }

}
