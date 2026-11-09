import Foundation

actor StadiaSearchService: PlaceSearching {
    private let endpoint: URL
    private let apiKey: String
    private let session: URLSession
    private var cache: [URL: (date: Date, response: StadiaResponse)] = [:]

    init(endpoint: URL = AppConfiguration.searchEndpoint, apiKey: String = AppConfiguration.stadiaAPIKey,
         session: URLSession = .shared) {
        self.endpoint = endpoint; self.apiKey = apiKey; self.session = session
    }

    func search(query: String, latitude: Double?, longitude: Double?) async throws -> [Place] {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return [] }
        return try await fetch("search", items: searchItems(query, latitude, longitude)).places
    }

    func suggestions(query: String, latitude: Double?, longitude: Double?) async throws -> [PlaceSuggestion] {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else { return [] }
        return try await fetch("autocomplete", items: searchItems(query, latitude, longitude)).suggestions
    }

    func resolve(_ suggestion: PlaceSuggestion) async throws -> Place {
        let response = try await fetch("place_details", items: [URLQueryItem(name: "ids", value: suggestion.id)])
        guard let place = response.places.first(where: { $0.id == suggestion.id }) else { throw URLError(.cannotParseResponse) }
        return place
    }

    private func searchItems(_ query: String, _ latitude: Double?, _ longitude: Double?) throws -> [URLQueryItem] {
        guard (latitude == nil) == (longitude == nil) else { throw URLError(.badURL) }
        var items = [URLQueryItem(name: "text", value: query.trimmingCharacters(in: .whitespacesAndNewlines)),
                     URLQueryItem(name: "size", value: "8")]
        if let latitude, let longitude {
            guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else {
                throw URLError(.badURL)
            }
            items += [URLQueryItem(name: "focus.point.lat", value: String(latitude)),
                      URLQueryItem(name: "focus.point.lon", value: String(longitude))]
        }
        return items
    }

    private func fetch(_ path: String, items: [URLQueryItem]) async throws -> StadiaResponse {
        guard !apiKey.isEmpty else { throw StadiaServiceError.missingKey }
        guard var components = URLComponents(url: endpoint.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = items + [URLQueryItem(name: "api_key", value: apiKey),
                                        URLQueryItem(name: "lang", value: Locale.preferredLanguages.first ?? "en")]
        guard let url = components.url else { throw URLError(.badURL) }
        try Task.checkCancellation()
        if let cached = cache[url], Date().timeIntervalSince(cached.date) < 300 { return cached.response }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("Harta-iOS/0.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        try StadiaServiceError.validate(response)
        let decoded = try JSONDecoder().decode(StadiaResponse.self, from: data)
        cache = cache.filter { Date().timeIntervalSince($0.value.date) < 300 }
        if cache.count >= 30, let oldest = cache.min(by: { $0.value.date < $1.value.date })?.key { cache.removeValue(forKey: oldest) }
        cache[url] = (Date(), decoded)
        return decoded
    }
}
