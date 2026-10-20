import Foundation

actor PhotonSearchService: PlaceSearching {
    private let endpoint: URL
    private let session: URLSession
    private var cache: [String: [Place]] = [:]
    private var cacheOrder: [String] = []
    private var nextRequestDate = Date.distantPast

    init(endpoint: URL = AppConfiguration.searchEndpoint, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func search(query: String, latitude: Double, longitude: Double) async throws -> [Place] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return [] }
        guard latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw URLError(.badURL)
        }
        let key = "\(query.lowercased())|\(Int(latitude * 100))|\(Int(longitude * 100))"
        if let cached = cache[key] { return cached }

        // Submit-only UI plus a minimum interval protects the public demo service.
        let start = max(Date.now, nextRequestDate)
        nextRequestDate = start.addingTimeInterval(1)
        let remaining = start.timeIntervalSinceNow
        if remaining > 0 { try await Task.sleep(for: .seconds(remaining)) }
        try Task.checkCancellation()
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "limit", value: "8")
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Harta-iOS/0.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else { throw URLError(.badServerResponse) }
        let places = try JSONDecoder().decode(PhotonResponse.self, from: data).places
        cache[key] = places
        cacheOrder.append(key)
        if cacheOrder.count > 30 { cache.removeValue(forKey: cacheOrder.removeFirst()) }
        return places
    }
}
