import Foundation
import Testing
@testable import Harta

struct VoiceCommandTests {
    private let home = Place(id: "home", name: "My apartment", address: "", latitude: 43, longitude: -79, savedIcon: "home")
    private let library = Place(id: "library", name: "Central Library", address: "Montreal", latitude: 45, longitude: -73)

    @Test func parsesBasicRequestsAndPreservesNames() throws {
        let search = try BasicVoiceCommandParser.parse("Find tennis clubs.")
        #expect(search.action == .search)
        #expect(search.destination == "tennis clubs")
        let route = try BasicVoiceCommandParser.parse("Walking directions to Central Library")
        #expect(route.action == .directions)
        #expect(route.destination == "Central Library")
        #expect(route.mode == .walking)
        #expect(try BasicVoiceCommandParser.parse("Go home").mode == nil)
        #expect(try BasicVoiceCommandParser.parse("directions to Work by bike").mode == .cycling)
    }

    @Test func preservesExplicitLocalityAndAvoidsWrongSavedMatch() throws {
        let command = try BasicVoiceCommandParser.parse("Find Central Library in Toronto")
        #expect(command.locality == "Toronto")
        #expect(SavedPlaceResolver.resolve(command, places: [library]) == .search("Central Library Toronto"))
    }

    @Test func matchesAliasesNamesAndAmbiguity() throws {
        let command = try BasicVoiceCommandParser.parse("Go home")
        #expect(SavedPlaceResolver.resolve(command, places: [home]) == .matches([home]))
        #expect(SavedPlaceResolver.resolve(command, places: []) == .missingAlias("Home"))
        let other = Place(id: "other", name: "Home", address: "", latitude: 44, longitude: -78)
        #expect(SavedPlaceResolver.resolve(command, places: [home, other]) == .matches([home, other]))
        let work = Place(id: "work", name: "Office", address: "", latitude: 44, longitude: -78, savedIcon: "work")
        #expect(SavedPlaceResolver.resolve(try BasicVoiceCommandParser.parse("directions to my work"), places: [work]) == .matches([work]))
        let exact = VoiceCommand(destination: "CENTRAL—LÍBRARY")
        #expect(SavedPlaceResolver.resolve(exact, places: [library]) == .matches([library]))
        #expect(SavedPlaceResolver.resolve(VoiceCommand(destination: "Library"), places: [library]) == .search("Library"))
        #expect(SavedPlaceResolver.resolve(VoiceCommand(destination: "Lib"), places: [library]) == .search("Lib"))
    }

    @Test func exactSavedNameWinsBeforePartialNames() {
        let other = Place(id: "other", name: "Central Library Annex", address: "", latitude: 43, longitude: -79)
        #expect(SavedPlaceResolver.resolve(VoiceCommand(destination: "Central Library"), places: [other, library]) == .matches([library]))
        #expect(SavedPlaceResolver.resolve(VoiceCommand(destination: "Library"), places: [other, library]) == .search("Library"))
    }

    @Test func rejectsEmptyCommandsAndUnsupportedFilters() {
        for text in ["", "   ", "directions to", "find", "Find cafes open now", "Find restaurants under $20", "Find cafes within 2 km"] {
            #expect(throws: VoiceCommandError.self) { try BasicVoiceCommandParser.parse(text) }
        }
    }

    @MainActor @Test func unavailableLanguageModelFallsBackToLocalParser() async throws {
        let extractor = AppleVoiceCommandExtractor(isModelAvailable: { false })
        let command = try await extractor.extract("Walking directions to Central Library")
        #expect(command.action == .directions)
        #expect(command.destination == "Central Library")
        #expect(command.mode == .walking)
    }

}
