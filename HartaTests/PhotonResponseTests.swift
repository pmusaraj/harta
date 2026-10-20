import Foundation
import Testing
@testable import Harta

struct PhotonResponseTests {
    @Test func rejectsInvalidSearchCoordinatesBeforeRequesting() async {
        let service = PhotonSearchService(endpoint: URL(string: "https://example.invalid")!)
        for (latitude, longitude) in [(Double.nan, 0.0), (0.0, Double.infinity), (91.0, 0.0), (0.0, 181.0)] {
            do {
                _ = try await service.search(query: "test", latitude: latitude, longitude: longitude)
                Issue.record("Invalid coordinates should be rejected")
            } catch {
                #expect((error as? URLError)?.code == .badURL)
            }
        }
    }

    @Test func parsesLongitudeFirstAndDeduplicates() throws {
        let data = Data(#"{"features":[{"geometry":{"type":"Point","coordinates":[-79.38,43.65]},"properties":{"osm_id":42,"osm_type":"N","name":"Market","street":"Front Street","housenumber":"93","city":"Toronto"}},{"geometry":{"type":"Point","coordinates":[-79.38,43.65]},"properties":{"osm_id":42,"osm_type":"N","name":"Market"}},{"geometry":{"type":"Point","coordinates":[300,95]},"properties":{}}]}"#.utf8)
        let places = try JSONDecoder().decode(PhotonResponse.self, from: data).places
        #expect(places.count == 1)
        #expect(places.first?.latitude == 43.65)
        #expect(places.first?.longitude == -79.38)
        #expect(places.first?.address == "93 Front Street, Toronto")
    }

    @Test func handlesMissingNamesAndShortCoordinates() throws {
        let data = Data(#"{"features":[{"geometry":{"type":"Point","coordinates":[2,48]},"properties":{"street":"Rue Test","housenumber":"5"}},{"geometry":{"type":"Point","coordinates":[]},"properties":{}}]}"#.utf8)
        let places = try JSONDecoder().decode(PhotonResponse.self, from: data).places
        #expect(places.count == 1)
        #expect(places.first?.name == "5 Rue Test")
    }
}
