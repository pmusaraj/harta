import Foundation
import Observation

@MainActor @Observable
final class SavedPlacesStore {
    private(set) var places: [Place] = []
    var errorMessage: String?
    private let fileURL: URL
    private var canWrite = true

    init(fileURL: URL = URL.applicationSupportDirectory.appending(path: "Harta/places.json")) {
        self.fileURL = fileURL
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return }
        do {
            places = try JSONDecoder().decode([Place].self, from: Data(contentsOf: fileURL))
        } catch {
            // Preserve unreadable data instead of overwriting it with an empty list.
            canWrite = false
            errorMessage = "Saved places couldn’t be read. Your existing file has been preserved."
        }
    }

    func contains(_ place: Place) -> Bool { places.contains { $0.id == place.id } }

    func toggle(_ place: Place) {
        guard canWrite else {
            errorMessage = "Saved places are unavailable because the existing file couldn’t be read."
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
        guard canWrite else {
            errorMessage = "Saved places are unavailable because the existing file couldn’t be read."
            return
        }
        persist(places.filter { !ids.contains($0.id) })
    }

    private func persist(_ updated: [Place]) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(updated).write(to: fileURL, options: .atomic)
            places = updated
            errorMessage = nil
        } catch {
            errorMessage = "Your change couldn’t be saved. Please try again."
        }
    }
}
