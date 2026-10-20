import Foundation

actor ValhallaRoutingService: RouteProviding {
    private let endpoint: URL
    private let session: URLSession
    private var nextRequest = Date.distantPast
    init(endpoint: URL = AppConfiguration.routingEndpoint, session: URLSession = .shared) {
        self.endpoint = endpoint; self.session = session
    }
    func route(from origin: Place, to destination: Place, mode: TravelMode) async throws -> MapRoute {
        let delay = max(0, nextRequest.timeIntervalSinceNow)
        nextRequest = Date().addingTimeInterval(delay + 1)
        try await Task.sleep(for: .seconds(delay))
        try Task.checkCancellation()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("com.musaraj.harta", forHTTPHeaderField: "X-Client-Id")
        request.setValue("Harta-iOS/0.1", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "locations": [["lat": origin.latitude, "lon": origin.longitude],
                          ["lat": destination.latitude, "lon": destination.longitude]],
            "costing": mode.rawValue,
            "directions_options": ["units": "kilometers", "language": "en-US"]
        ])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        try Task.checkCancellation()
        return try JSONDecoder().decode(ValhallaResponse.self, from: data).route()
    }
}
