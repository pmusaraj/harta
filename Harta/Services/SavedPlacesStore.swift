import Foundation
import Observation

@MainActor @Observable
final class SavedPlacesStore {
    private(set) var places: [Place] = []
    var errorMessage: String?
    private let fileURL: URL
    private var canWrite = true
    let isReadOnly: Bool
    private(set) var cloudBaseline: [Place] = []

    private struct Snapshot: Codable {
        var places: [Place]
        var cloudBaseline: [Place]
    }

    init(fileURL: URL = URL.applicationSupportDirectory.appending(path: "Harta/places.json"), isReadOnly: Bool = false) {
        self.isReadOnly = isReadOnly
        self.fileURL = fileURL
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            if let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
                places = snapshot.places
                cloudBaseline = snapshot.cloudBaseline
            } else {
                places = try JSONDecoder().decode([Place].self, from: data)
            }
        } catch {
            // Preserve unreadable data instead of overwriting it with an empty list.
            canWrite = false
            errorMessage = "Saved places couldn’t be read. Your existing file has been preserved."
        }
    }

    func contains(_ place: Place) -> Bool { places.contains { $0.id == place.id } }

    @discardableResult
    func rename(_ place: Place, to name: String) -> Bool {
        guard canWrite, !isReadOnly else {
            errorMessage = "This map cannot be edited. It is read-only or its saved file could not be read."
            return false
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a name for this place."
            return false
        }
        guard let index = places.firstIndex(where: { $0.id == place.id }) else {
            errorMessage = "This place is no longer saved. Save it before renaming it."
            return false
        }
        var updated = places
        updated[index].name = trimmed
        return persist(updated)
    }

    func icon(for place: Place) -> SavedPlaceIcon? {
        places.first { $0.id == place.id }?.icon
    }

    @discardableResult
    func setIcon(_ icon: SavedPlaceIcon, for place: Place) -> Bool {
        guard canWrite, !isReadOnly else {
            errorMessage = "This map cannot be edited. It is read-only or its saved file could not be read."
            return false
        }
        guard let index = places.firstIndex(where: { $0.id == place.id }) else { return false }
        var updated = places
        updated[index].savedIcon = icon.rawValue
        return persist(updated)
    }

    func tint(for place: Place) -> SavedPlaceTint {
        places.first { $0.id == place.id }?.tint ?? .teal
    }

    @discardableResult
    func setTint(_ tint: SavedPlaceTint, for place: Place) -> Bool {
        guard canWrite, !isReadOnly else {
            errorMessage = "This map cannot be edited. It is read-only or its saved file could not be read."
            return false
        }
        guard let index = places.firstIndex(where: { $0.id == place.id }) else { return false }
        var updated = places
        updated[index].savedTint = tint.rawValue
        return persist(updated)
    }

    func toggle(_ place: Place) {
        guard canWrite, !isReadOnly else {
            errorMessage = "This map cannot be edited. It is read-only or its saved file could not be read."
            return
        }
        var updated = places
        if let index = updated.firstIndex(where: { $0.id == place.id }) {
            updated.remove(at: index)
        } else {
            updated.insert(place, at: 0)
        }
        persist(updated)
    }

    func remove(ids: Set<String>) {
        guard canWrite, !isReadOnly else {
            errorMessage = "This map cannot be edited. It is read-only or its saved file could not be read."
            return
        }
        persist(places.filter { !ids.contains($0.id) })
    }

    /// Commits cloud data and its baseline together, preserving edits made during the request.
    @discardableResult
    func receiveCloud(_ remote: [Place], uploadedLocal: [Place]? = nil) -> Bool {
        guard canWrite else { return false }
        let updated = isReadOnly ? remote : PlaceMerge.merge(
            baseline: uploadedLocal ?? cloudBaseline, local: places, remote: remote)
        return persist(updated, baseline: remote)
    }

    @discardableResult
    private func persist(_ updated: [Place], baseline: [Place]? = nil) -> Bool {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(Snapshot(places: updated, cloudBaseline: baseline ?? cloudBaseline)).write(to: fileURL, options: .atomic)
            places = updated
            if let baseline { cloudBaseline = baseline }
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Your change couldn’t be saved. Please try again."
            return false
        }
    }
}
