import Foundation
@testable import Harta

actor CombinedSearchService: PlaceSearching {
    struct Request: Sendable {
        let query: String
        let latitude: Double?
        let longitude: Double?
    }
    private(set) var requests: [Request] = []
    let results: [Place]
    let fails: Bool
    init(results: [Place] = [], fails: Bool = false) { self.results = results; self.fails = fails }
    func search(query: String, latitude: Double?, longitude: Double?) async throws -> [Place] {
        requests.append(Request(query: query, latitude: latitude, longitude: longitude))
        if fails { throw URLError(.notConnectedToInternet) }
        return results
    }
}
