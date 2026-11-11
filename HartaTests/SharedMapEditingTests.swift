import CloudKit
import Foundation
import Testing
@testable import Harta

@MainActor
struct SharedMapEditingTests {
    private func place(_ id: String) -> Place {
        Place(id: id, name: id, address: "", latitude: 43, longitude: -79)
    }

    @Test func ownerAndEditorChangesMergeInBothDirections() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let owner = SavedPlacesStore(fileURL: directory.appending(path: "owner.json"))
        let editor = SavedPlacesStore(fileURL: directory.appending(path: "editor.json"), isReadOnly: true)
        let a = place("a"), b = place("b"), c = place("c")
        var cloud = [a, b]
        #expect(owner.receiveCloud(cloud))
        #expect(editor.receiveCloud(cloud))
        editor.setReadOnly(false)
        #expect(owner.rename(a, to: "Owner rename"))
        editor.remove(ids: [b.id])
        editor.toggle(c)
        #expect(editor.setTint(.blue, for: c))
        try await SavedPlacesSync.sync(store: owner, remote: cloud) { cloud = $0 }
        try await SavedPlacesSync.sync(store: editor, remote: cloud) { cloud = $0 }
        try await SavedPlacesSync.sync(store: owner, remote: cloud) { cloud = $0 }
        #expect(owner.places == editor.places)
        #expect(owner.places.first { $0.id == a.id }?.name == "Owner rename")
        #expect(!owner.contains(b))
        #expect(owner.tint(for: c) == .blue)
        #expect(!editor.hasPendingChanges)
    }

    @Test func rejectedUploadKeepsEditsAndBaselineForRetry() async throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SavedPlacesStore(fileURL: file)
        let a = place("a"), b = place("b")
        #expect(store.receiveCloud([a]))
        #expect(store.rename(a, to: "Editor rename"))
        do {
            try await SavedPlacesSync.sync(store: store, remote: [a]) { _ in
                throw CKError(.serverRecordChanged)
            }
            Issue.record("A rejected upload must throw")
        } catch {
            #expect((error as? CKError)?.code == .serverRecordChanged)
        }
        let restored = SavedPlacesStore(fileURL: file)
        #expect(restored.cloudBaseline == [a])
        #expect(restored.hasPendingChanges)
        var cloud = [a, b]
        try await SavedPlacesSync.sync(store: restored, remote: cloud) { cloud = $0 }
        #expect(cloud.first { $0.id == a.id }?.name == "Editor rename")
        #expect(cloud.contains(b))
        #expect(!restored.hasPendingChanges)
    }

    @Test func editsDuringSharedUploadRemainPending() async throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SavedPlacesStore(fileURL: file)
        let a = place("a")
        store.toggle(a)
        try await SavedPlacesSync.sync(store: store, remote: []) { _ in
            #expect(store.rename(a, to: "Edited during upload"))
        }
        #expect(store.cloudBaseline == [a])
        #expect(store.places.first?.name == "Edited during upload")
        #expect(store.hasPendingChanges)
    }

    @Test func downgradeRetainsPendingEditsAndBlocksNewMutations() throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SavedPlacesStore(fileURL: file)
        let a = place("a"), b = place("b")
        #expect(store.receiveCloud([a]))
        #expect(store.rename(a, to: "Pending rename"))
        store.setReadOnly(true)
        #expect(store.receiveCloud([a, b]))
        #expect(store.hasPendingChanges)
        #expect(store.places.first { $0.id == a.id }?.name == "Pending rename")
        #expect(!store.rename(a, to: "Blocked"))
        store.remove(ids: [b.id])
        #expect(store.contains(b))
        let restored = SavedPlacesStore(fileURL: file, isReadOnly: true)
        #expect(restored.isReadOnly)
        #expect(restored.hasPendingChanges)
        #expect(restored.places == store.places)
    }

    @Test func replacingJoinedMapClearsOldPendingEditsAndBaseline() {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SavedPlacesStore(fileURL: file)
        let a = place("a"), b = place("b")
        store.toggle(a)
        #expect(store.hasPendingChanges)
        store.setReadOnly(true)
        #expect(store.replaceCloud([b]))
        #expect(store.places == [b])
        #expect(store.cloudBaseline == [b])
        #expect(!store.hasPendingChanges)
    }
}
