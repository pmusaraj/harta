import Foundation
import Testing
@testable import Harta

struct PlaceSearchRankingTests {
    private let saved = Place(id: "saved", name: "Riverside Club", address: "Montreal", latitude: 45.5, longitude: -73.57, savedIcon: "tennis")

    @Test func recognizesRelativeAreasWithoutGeocodingThem() throws {
        for text in ["tennis near me", "tennis nearby", "nearby tennis", "tennis around me", "tennis near my location"] {
            let request = PlaceSearchRequest(text: text)
            #expect(request.destination == "tennis")
            #expect(request.locality == nil)
            #expect(request.area == .currentLocation)
        }
        let voice = try BasicVoiceCommandParser.parse("Find tennis courts near me")
        #expect(voice.destination == "tennis courts")
        #expect(voice.locality == nil)
        #expect(voice.area == .currentLocation)
        #expect(PlaceSearchRequest(text: "coffee in this area").area == .map)
        #expect(PlaceSearchRequest(text: "coffee in Toronto").locality == "Toronto")
    }

    @Test func categoriesMatchSavedIconsButNamedVenuesDoNotMatchEveryClub() {
        #expect(PlaceSearchRanking.relevance(saved, request: .init(text: "tennis courts")) > 0)
        #expect(PlaceSearchRanking.relevance(saved, request: .init(text: "Other Tennis Club")) == 0)
        #expect(PlaceSearchRanking.category(for: "tennis clubs") == .tennis)
        #expect(PlaceSearchRanking.category(for: "Riverside Tennis Club") == nil)
        #expect(PlaceSearchRanking.category(for: "coffee") == .cafe)
    }

    @Test func matchesSmallTyposAndWordOrderButNotShortSubstrings() {
        #expect(PlaceSearchRanking.relevance(saved, request: .init(text: "Riversdie club")) > 0)
        #expect(PlaceSearchRanking.relevance(saved, request: .init(text: "club Riverside")) > 0)
        #expect(PlaceSearchRanking.relevance(saved, request: .init(text: "Riv")) == 0)
    }

    @Test func namedLocalityFiltersSavedMatches() {
        #expect(PlaceSearchRanking.relevance(saved, request: .init(text: "tennis in Montreal")) > 0)
        #expect(PlaceSearchRanking.relevance(saved, request: .init(text: "tennis in Toronto")) == 0)
    }

    @Test func combinesDeduplicatesAndPreservesSavedMetadata() {
        let duplicate = Place(id: "online", name: saved.name, address: "Montreal", latitude: saved.latitude, longitude: saved.longitude)
        let other = Place(id: "other", name: "Tennis Courts", address: "Montreal", latitude: 45.51, longitude: -73.57)
        let result = PlaceSearchRanking.merge(saved: [saved], online: [duplicate, other], request: .init(text: "tennis"), latitude: 45.5, longitude: -73.57)
        #expect(result.count == 2)
        #expect(result.contains(saved))
        #expect(!result.contains { $0.id == "online" })
    }

    @Test func nearbyCategoryOutranksDistantSavedCategoryAndExactNameStillWins() {
        let distant = Place(id: "far", name: "Distant Club", address: "", latitude: 43.65, longitude: -79.38, savedIcon: "tennis")
        let near = Place(id: "near", name: "Tennis Courts", address: "", latitude: 45.5, longitude: -73.57)
        let result = PlaceSearchRanking.merge(saved: [distant], online: [near], request: .init(text: "tennis"), latitude: 45.5, longitude: -73.57)
        #expect(result.first?.id == "near")
        let exact = PlaceSearchRanking.merge(saved: [distant], online: [near], request: .init(text: "Distant Club"), latitude: 45.5, longitude: -73.57)
        #expect(exact.first == distant)
    }
}
