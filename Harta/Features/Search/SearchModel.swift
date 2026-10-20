import Foundation
import Observation

@MainActor @Observable
final class SearchModel {
    var query = ""
    private(set) var results: [Place] = []
    private(set) var isSearching = false
    private(set) var hasSearched = false
    private(set) var errorMessage: String?
    private let service: any PlaceSearching
    private var task: Task<Void, Never>?
    private var generation = UUID()

    init(service: any PlaceSearching = PhotonSearchService()) { self.service = service }

    @discardableResult
    func submit(latitude: Double, longitude: Double) -> Task<Void, Never>? {
        cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }
        let requestID = UUID()
        generation = requestID
        isSearching = true
        errorMessage = nil
        results = []
        hasSearched = true
        task = Task { [weak self, service] in
            do {
                let places = try await service.search(query: trimmed, latitude: latitude, longitude: longitude)
                try Task.checkCancellation()
                guard let self, self.generation == requestID else { return }
                self.results = places
                self.isSearching = false
            } catch {
                guard let self, self.generation == requestID, !Task.isCancelled else { return }
                self.errorMessage = "Search is unavailable. Check your connection and try again."
                self.isSearching = false
            }
        }
        return task
    }

    func queryChanged() {
        cancel()
        results = []
        hasSearched = false
        errorMessage = nil
    }

    func cancel() {
        task?.cancel()
        task = nil
        generation = UUID()
        isSearching = false
    }
}
