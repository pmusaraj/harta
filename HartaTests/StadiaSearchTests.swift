import Foundation
import Testing
@testable import Harta

@Suite(.serialized)
struct StadiaSearchTests {
    @Test func decodesSuggestionsWithoutInventingCoordinates() throws {
        let json = #"{"features":[{"properties":{"gid":"osm:1","name":"Library","coarse_location":"Toronto, ON"}}]}"#
        let response = try JSONDecoder().decode(StadiaResponse.self, from: Data(json.utf8))
        #expect(response.suggestions.first?.address == "Toronto, ON")
        #expect(response.places.isEmpty)
    }

    @Test func rejectsInvalidGeometryAndDuplicateIDs() throws {
        let json = #"{"features":[{"geometry":{"type":"Point","coordinates":[-79,43]},"properties":{"gid":"osm:1","name":"Library","formatted_address_line":"1 Main Street"}},{"geometry":{"type":"Point","coordinates":[-79,43]},"properties":{"gid":"osm:1","name":"Duplicate"}},{"geometry":{"type":"Point","coordinates":[-79,143]},"properties":{"gid":"osm:2","name":"Invalid"}}]}"#
        let response = try JSONDecoder().decode(StadiaResponse.self, from: Data(json.utf8))
        #expect(response.places.count == 1)
        #expect(response.places.first?.latitude == 43)
        #expect(response.places.first?.address == "1 Main Street")
    }

    @Test func missingKeyFailsWithoutNetwork() async {
        let service = StadiaSearchService(apiKey: "")
        await #expect(throws: StadiaServiceError.self) {
            try await service.search(query: "Toronto", latitude: nil, longitude: nil)
        }
    }

    @Test func autocompleteUsesV2AndCachesWithoutLookingUpEveryResult() async throws {
        StadiaTestURLProtocol.requests = []
        StadiaTestURLProtocol.status = 200
        StadiaTestURLProtocol.body = #"{"features":[{"properties":{"gid":"osm:1","name":"Library","coarse_location":"Toronto"}}]}"#
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StadiaTestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let service = StadiaSearchService(apiKey: "test-key", session: session)
        let first = try await service.suggestions(query: "Library", latitude: 43, longitude: -79)
        let second = try await service.suggestions(query: "Library", latitude: 43, longitude: -79)
        #expect(first == second)
        #expect(StadiaTestURLProtocol.requests.count == 1)
        let url = try #require(StadiaTestURLProtocol.requests.first?.url)
        #expect(url.path == "/geocoding/v2/autocomplete")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "focus.point.lat", value: "43.0")))

        StadiaTestURLProtocol.body = #"{"features":[{"geometry":{"type":"Point","coordinates":[-79,43]},"properties":{"gid":"osm:1","name":"Library"}}]}"#
        let place = try await service.resolve(try #require(first.first))
        #expect(place.longitude == -79)
        #expect(StadiaTestURLProtocol.requests.count == 2)
        #expect(StadiaTestURLProtocol.requests.last?.url?.path == "/geocoding/v2/place_details")
    }

    @Test func reportsQuotaWithoutRetrying() async {
        StadiaTestURLProtocol.requests = []
        StadiaTestURLProtocol.status = 429
        StadiaTestURLProtocol.body = "{}"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StadiaTestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let service = StadiaSearchService(apiKey: "test-key", session: session)
        await #expect(throws: StadiaServiceError.self) {
            try await service.suggestions(query: "Library", latitude: nil, longitude: nil)
        }
        #expect(StadiaTestURLProtocol.requests.count == 1)
    }
}
