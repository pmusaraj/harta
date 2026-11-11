import Foundation

/// The same merge and acknowledgement rules apply to owners and invited editors.
@MainActor
enum SavedPlacesSync {
    static func sync(store: SavedPlacesStore, remote: [Place], isNew: Bool = false,
                     save: ([Place]) async throws -> Void) async throws {
        let local = store.places
        let merged = PlaceMerge.merge(baseline: isNew ? [] : store.cloudBaseline,
                                      local: local, remote: remote)
        if merged != remote || isNew { try await save(merged) }
        guard store.receiveCloud(merged, uploadedLocal: local) else { throw SaveError.localSave }
    }

    private enum SaveError: LocalizedError {
        case localSave
        var errorDescription: String? { "The map could not be saved on this device. Your changes have not been discarded." }
    }
}
