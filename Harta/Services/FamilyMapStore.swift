import CloudKit
import Observation

@MainActor @Observable
final class FamilyMapStore {
    static let shared = FamilyMapStore()
    static let containerIdentifier = "iCloud.com.musaraj.harta"

    let personal = SavedPlacesStore()
    private(set) var family = SavedPlacesStore(
        fileURL: URL.applicationSupportDirectory.appending(path: "Harta/family-places.json"), isReadOnly: true)
    var showingFamily = false
    private(set) var enabled: Bool
    private(set) var joined: FamilyMapReference?
    private(set) var busy = false
    private(set) var status = ""
    private(set) var lastSynced: Date?
    var errorMessage: String?
    var presentedShare: CloudSharePresentation?

    var activeStore: SavedPlacesStore { showingFamily && joined != nil ? family : personal }
    var container: CKContainer { CKContainer(identifier: Self.containerIdentifier) }
    private let defaults = UserDefaults.standard
    private let ownerID = CKRecord.ID(recordName: "FamilyMap", zoneID: CKRecordZone.ID(zoneName: "FamilyMap"))

    private init() {
        enabled = UserDefaults.standard.bool(forKey: "familyMap.enabled")
        joined = UserDefaults.standard.data(forKey: "familyMap.joined")
            .flatMap { try? JSONDecoder().decode(FamilyMapReference.self, from: $0) }
        showingFamily = joined != nil
    }

    func refresh() async {
        guard !busy, enabled || joined != nil else { return }
        busy = true
        defer { busy = false }
        do {
            try await checkAccount()
            // A failure syncing a user's own map must not prevent their joined map from syncing.
            var syncError: Error?
            if enabled {
                do { try await syncOwner() } catch { syncError = error }
            }
            if let joined {
                do { try await syncJoined(joined) } catch { syncError = error }
            }
            if let syncError { throw syncError }
            lastSynced = .now
            status = "Up to date"
            errorMessage = nil
        } catch { report(error) }
    }

    func sharePersonalMap() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await checkAccount()
            _ = try await container.privateCloudDatabase.save(CKRecordZone(zoneID: ownerID.zoneID))
            enabled = true
            defaults.set(true, forKey: "familyMap.enabled")
            try await syncOwner()
            let database = container.privateCloudDatabase
            let root = try await database.record(for: ownerID)
            if let reference = root.share {
                guard let share = try await database.record(for: reference.recordID) as? CKShare else {
                    throw SyncError.invalidShare
                }
                presentedShare = CloudSharePresentation(share: share)
            } else {
                let share = CKShare(rootRecord: root)
                share[CKShare.SystemFieldKey.title] = "Shared map" as CKRecordValue
                share.publicPermission = .none
                let result = try await database.modifyRecords(saving: [root, share], deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: true)
                for value in result.saveResults.values { _ = try value.get() }
                guard let savedShare = try result.saveResults[share.recordID]?.get() as? CKShare else {
                    throw SyncError.invalidShare
                }
                presentedShare = CloudSharePresentation(share: savedShare)
            }
            errorMessage = nil
            status = "Up to date"
        } catch { report(error) }
    }

    func accept(_ metadata: CKShare.Metadata) async {
        guard metadata.containerIdentifier == Self.containerIdentifier else { return }
        // Share acceptance can arrive while a foreground refresh is running.
        while busy {
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
        }
        busy = true
        defer { busy = false }
        do {
            try await checkAccount()
            guard let rootID = metadata.hierarchicalRootRecordID else { throw SyncError.invalidShare }
            if metadata.participantRole == .owner {
                showingFamily = false
                return
            }
            _ = try await container.accept(metadata)
            let reference = FamilyMapReference(rootID)
            if joined != reference {
                guard family.replaceCloud([]) else { throw SyncError.localSave }
                family.setReadOnly(true)
            }
            joined = reference
            defaults.set(try JSONEncoder().encode(reference), forKey: "familyMap.joined")
            showingFamily = true
            try await syncJoined(reference)
            lastSynced = .now
            status = "Up to date"
            errorMessage = nil
        } catch { report(error) }
    }

    func manageJoinedMap() async {
        guard !busy, let joined else { return }
        busy = true
        defer { busy = false }
        do {
            try await checkAccount()
            let root = try await container.sharedCloudDatabase.record(for: joined.recordID)
            guard let reference = root.share else { throw SyncError.invalidShare }
            guard let share = try await container.sharedCloudDatabase.record(for: reference.recordID) as? CKShare else {
                throw SyncError.invalidShare
            }
            presentedShare = CloudSharePresentation(share: share)
        } catch { report(error) }
    }

    func sharingStopped() {
        // Refresh verifies whether the participant still has access. An owner keeps their places.
        presentedShare = nil
        Task { await refresh() }
    }

    private func checkAccount() async throws {
        let accountStatus = try await container.accountStatus()
        if accountStatus == .noAccount || accountStatus == .restricted { forgetFamily() }
        guard accountStatus == .available else { throw SyncError.noAccount }
        let account = try await container.userRecordID().recordName
        if let previous = defaults.string(forKey: "familyMap.account"), previous != account {
            // Never upload the previous user's cache into a different iCloud account.
            forgetFamily()
            throw SyncError.accountChanged
        }
        defaults.set(account, forKey: "familyMap.account")
    }

    private func syncOwner() async throws {
        let database = container.privateCloudDatabase
        for attempt in 0..<3 {
            do {
                let record: CKRecord
                do { record = try await database.record(for: ownerID) }
                catch let error as CKError where error.code == .unknownItem {
                    record = CKRecord(recordType: "FamilyMap", recordID: ownerID)
                }
                try await SavedPlacesSync.sync(store: personal, remote: decode(record),
                                               isNew: record.creationDate == nil) { places in
                    try await self.upload(places, to: record, database: database)
                }
                return
            } catch let error as CKError where error.code == .serverRecordChanged && attempt < 2 {
                // Fetch the latest version and merge again. Never acknowledge a rejected write.
                continue
            }
        }
    }

    private func syncJoined(_ reference: FamilyMapReference) async throws {
        let database = container.sharedCloudDatabase
        for attempt in 0..<3 {
            let record: CKRecord
            let share: CKShare
            do {
                record = try await database.record(for: reference.recordID)
                guard let shareID = record.share?.recordID,
                      let fetchedShare = try await database.record(for: shareID) as? CKShare else {
                    throw SyncError.invalidShare
                }
                share = fetchedShare
            } catch let error as CKError where error.code == .unknownItem || error.code == .zoneNotFound || error.code == .permissionFailure {
                forgetFamily()
                throw SyncError.accessRemoved
            }

            // Recheck server permissions before each upload, including conflict retries.
            let canEdit = share.currentUserParticipant?.permission == .readWrite
            family.setReadOnly(!canEdit)
            let remote = try decode(record)
            guard canEdit else {
                // Retain unsent edits if an editor becomes a viewer; do not silently discard them.
                guard family.receiveCloud(remote) else { throw SyncError.localSave }
                if family.hasPendingChanges { throw SyncError.editPermissionRemoved }
                return
            }
            do {
                try await SavedPlacesSync.sync(store: family, remote: remote) { places in
                    try await self.upload(places, to: record, database: database)
                }
                return
            } catch let error as CKError where error.code == .serverRecordChanged && attempt < 2 {
                continue
            } catch let error as CKError where error.code == .permissionFailure {
                // A write denial can mean a downgrade, not loss of read access. Keep pending edits.
                family.setReadOnly(true)
                throw SyncError.editPermissionRemoved
            }
        }
    }

    private func upload(_ places: [Place], to record: CKRecord, database: CKDatabase) async throws {
        let file = URL.temporaryDirectory.appending(path: "family-map-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        try JSONEncoder().encode(places).write(to: file, options: .atomic)
        record["places"] = CKAsset(fileURL: file)
        // Reject stale snapshots in both private and shared databases.
        _ = try await database.save(record)
    }

    private func decode(_ record: CKRecord) throws -> [Place] {
        guard let asset = record["places"] as? CKAsset else {
            if record.creationDate == nil { return [] }
            throw SyncError.invalidShare
        }
        guard let url = asset.fileURL else { throw SyncError.invalidShare }
        let places = try JSONDecoder().decode([Place].self, from: Data(contentsOf: url))
        guard Set(places.map(\.id)).count == places.count else { throw SyncError.invalidShare }
        return places
    }

    private func forgetFamily() {
        joined = nil
        showingFamily = false
        defaults.removeObject(forKey: "familyMap.joined")
        family.setReadOnly(true)
        _ = family.replaceCloud([])
    }

    private func report(_ error: Error) {
        status = "Sync needs attention"
        errorMessage = error.localizedDescription
    }

    private enum SyncError: LocalizedError {
        case noAccount, accountChanged, invalidShare, localSave, accessRemoved, editPermissionRemoved
        var errorDescription: String? {
            switch self {
            case .noAccount: "Sign in to iCloud in Settings to sync your shared map."
            case .accountChanged: "Your iCloud account changed. Sign back in to the original account to sync this map. Your personal places are preserved."
            case .invalidShare: "This shared map could not be read. Please ask the owner for a new invitation."
            case .localSave: "The map could not be saved on this device. Your changes have not been discarded."
            case .editPermissionRemoved: "Editing access is unavailable. Unsent changes remain on this device and will sync if the owner restores editing access."
            case .accessRemoved: "You no longer have access to this shared map. Your personal places are preserved."
            }
        }
    }
}
