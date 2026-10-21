import Foundation
import Observation

@MainActor @Observable
final class SearchModel {
    var query = ""
    private(set) var results: [Place] = []
    private(set) var isSearching = false
    private(set) var hasSearched = false
    private(set) var errorMessage: String?
    private(set) var locationMessage: String?
    private(set) var needsLocation = false
    private(set) var request: PlaceSearchRequest?
    private let service: any PlaceSearching
    private var task: Task<Void, Never>?
    private var generation = UUID()

    init(service: any PlaceSearching = PhotonSearchService()) { self.service = service }

    @discardableResult
    func submit(query submittedQuery: String? = nil, request submittedRequest: PlaceSearchRequest? = nil,
                latitude: Double, longitude: Double, currentLocation: LocationFix? = nil,
                savedPlaces: [Place] = []) -> Task<Void, Never>? {
        cancel()
        let request = submittedRequest ?? PlaceSearchRequest(text: submittedQuery ?? query)
        guard request.destination.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return nil }
        self.request = request
        let requestID = generation
        hasSearched = true
        errorMessage = nil
        locationMessage = nil
        needsLocation = false
        results = []
        let fix = currentLocation.flatMap { abs($0.timestamp.timeIntervalSinceNow) < 120 ? $0 : nil }
        var biasLatitude: Double? = latitude
        var biasLongitude: Double? = longitude
        if request.locality != nil {
            biasLatitude = nil; biasLongitude = nil
        } else if request.area != .map, let fix {
            biasLatitude = fix.latitude; biasLongitude = fix.longitude
        } else if request.area == .currentLocation {
            needsLocation = true
            errorMessage = "Your current location isn’t available. Enable location access or search the map area."
            return nil
        } else if request.area == .automatic {
            locationMessage = "Searching the map area because your current location isn’t available."
        }
        let aliasCommand = VoiceCommand(destination: request.destination, locality: request.locality)
        if aliasCommand.savedAlias != nil {
            switch SavedPlaceResolver.resolve(aliasCommand, places: savedPlaces) {
            case .matches(let places): results = places; return nil
            case .missingAlias(let alias):
                errorMessage = "No saved \(alias) found. Save a place with that name or icon."
                return nil
            case .search: break
            }
        }
        results = PlaceSearchRanking.merge(saved: savedPlaces, online: [], request: request,
                                           latitude: biasLatitude, longitude: biasLongitude)
        isSearching = true
        let searchLatitude = biasLatitude, searchLongitude = biasLongitude
        task = Task { [weak self, service] in
            do {
                let places = try await service.search(query: request.query, latitude: searchLatitude, longitude: searchLongitude)
                try Task.checkCancellation()
                guard let self, self.generation == requestID else { return }
                self.results = PlaceSearchRanking.merge(saved: savedPlaces, online: places, request: request,
                                                       latitude: searchLatitude, longitude: searchLongitude)
                self.isSearching = false
            } catch {
                guard let self, self.generation == requestID, !Task.isCancelled else { return }
                self.errorMessage = "Online search is unavailable. Saved matches are still shown. Check your connection and try again."
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
        locationMessage = nil
        needsLocation = false
        request = nil
    }

    func cancel() {
        task?.cancel()
        task = nil
        generation = UUID()
        isSearching = false
    }
}
