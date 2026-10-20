protocol RouteProviding: Sendable {
    func route(from origin: Place, to destination: Place, mode: TravelMode) async throws -> MapRoute
}
