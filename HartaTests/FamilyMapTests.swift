import Foundation
import Testing
@testable import Harta

@MainActor
struct FamilyMapTests {
    private func place(_ id: String, icon: String? = nil) -> Place {
        Place(id: id, name: id, address: "", latitude: 43, longitude: -79, savedIcon: icon)
    }

    @Test func mergesIndependentEditsAndDeletions() {
        let a = place("a"), b = place("b"), c = place("c")
        let edited = place("b", icon: "home")
        let merged = PlaceMerge.merge(baseline: [a, b], local: [edited], remote: [a, b, c])
        #expect(merged == [edited, c])
    }

    @Test func localChangeWinsSamePlaceConflict() {
        let original = place("a")
        let local = place("a", icon: "home")
        let remote = place("a", icon: "work")
        #expect(PlaceMerge.merge(baseline: [original], local: [local], remote: [remote]) == [local])
        #expect(PlaceMerge.merge(baseline: [original], local: [original], remote: []) == [])
    }

    @Test func readOnlyStoreRejectsEveryMutation() throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SavedPlacesStore(fileURL: file, isReadOnly: true)
        let original = place("a")
        #expect(store.receiveCloud([original]))
        store.toggle(original)
        store.remove(ids: [original.id])
        #expect(!store.setIcon(.home, for: original))
        #expect(!store.setTint(.blue, for: original))
        #expect(store.places == [original])
        #expect(SavedPlacesStore(fileURL: file, isReadOnly: true).places == [original])
    }

    @Test func editsDuringUploadRemainPendingAfterRelaunch() throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SavedPlacesStore(fileURL: file)
        let original = place("a"), otherDevice = place("b")
        store.toggle(original)
        let uploading = store.places
        #expect(store.setIcon(.home, for: original))
        #expect(store.receiveCloud([original, otherDevice], uploadedLocal: uploading))
        let restored = SavedPlacesStore(fileURL: file)
        #expect(restored.cloudBaseline == [original, otherDevice])
        #expect(restored.icon(for: original) == .home)
        #expect(restored.contains(otherDevice))
        let next = PlaceMerge.merge(baseline: restored.cloudBaseline, local: restored.places, remote: [original, otherDevice])
        #expect(next.first?.savedIcon == SavedPlaceIcon.home.rawValue)
    }

    @Test func deletionDuringUploadIsNotResurrected() {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SavedPlacesStore(fileURL: file)
        let original = place("a")
        store.toggle(original)
        let uploading = store.places
        store.remove(ids: [original.id])
        #expect(store.receiveCloud(uploading, uploadedLocal: uploading))
        #expect(store.places.isEmpty)
        #expect(store.cloudBaseline == uploading)
        #expect(PlaceMerge.merge(baseline: store.cloudBaseline, local: [], remote: uploading).isEmpty)
    }
}
