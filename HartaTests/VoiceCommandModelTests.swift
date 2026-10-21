import Foundation
import Testing
@testable import Harta

@MainActor
struct VoiceCommandModelTests {
    private func store() -> SavedPlacesStore {
        SavedPlacesStore(fileURL: URL.temporaryDirectory.appending(path: "voice-\(UUID()).json"))
    }

    @Test(.timeLimit(.minutes(1))) func submitsOnlyExtractedSearchWithoutPublishingTranscript() async {
        let speech = TestVoiceTranscriber()
        let service = VoiceSearchService()
        let search = SearchModel(service: service)
        let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: TestVoiceExtractor())
        let task = model.start(store: store(), search: search, latitude: 43, longitude: -79)
        while speech.continuation == nil { await Task.yield() }
        #expect(model.status == .listening)
        model.stop()
        #expect(speech.stopped)
        #expect(model.status == .processing)
        speech.finish("Find tennis clubs")
        await task.value
        while search.isSearching { await Task.yield() }
        #expect(await service.queries == ["tennis clubs"])
        #expect(search.query.isEmpty)
        #expect(search.results.first?.name == "tennis clubs")
        #expect(model.status == nil)
    }

    @Test(.timeLimit(.minutes(1))) func missingHomeNeverGoesToNetwork() async {
        let speech = TestVoiceTranscriber()
        let service = VoiceSearchService()
        let search = SearchModel(service: service)
        let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: TestVoiceExtractor())
        let task = model.start(store: store(), search: search, latitude: 43, longitude: -79)
        while speech.continuation == nil { await Task.yield() }
        speech.finish("Go home")
        await task.value
        #expect(model.errorMessage?.contains("No saved Home") == true)
        #expect(await service.queries.isEmpty)
        #expect(!search.hasSearched)
    }

    @Test(.timeLimit(.minutes(1))) func resolvesSavedDirectionsLocally() async throws {
        let file = URL.temporaryDirectory.appending(path: "voice-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let saved = SavedPlacesStore(fileURL: file)
        let home = Place(id: "home", name: "Apartment", address: "", latitude: 43, longitude: -79, savedIcon: "home")
        saved.toggle(home)
        let speech = TestVoiceTranscriber()
        let service = VoiceSearchService()
        let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: TestVoiceExtractor())
        let task = model.start(store: saved, search: SearchModel(service: service), latitude: 0, longitude: 0)
        while speech.continuation == nil { await Task.yield() }
        speech.finish("Drive home")
        await task.value
        #expect(model.selection?.place == home)
        #expect(model.selection?.command.action == .directions)
        #expect(model.selection?.command.mode == .driving)
        #expect(await service.queries.isEmpty)
    }

    @Test(.timeLimit(.minutes(1))) func cancelRejectsLateSpeechAndAllowsRetry() async {
        let speech = TestVoiceTranscriber()
        let service = VoiceSearchService()
        let search = SearchModel(service: service)
        let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: TestVoiceExtractor())
        let request = model.start(store: store(), search: search, latitude: 0, longitude: 0)
        while speech.continuation == nil { await Task.yield() }
        model.cancel()
        #expect(speech.cancelled)
        speech.finish("Find cafe")
        await request.value
        #expect(await service.queries.isEmpty)
        #expect(model.status == nil)
        let retry = model.start(store: store(), search: search, latitude: 0, longitude: 0)
        while speech.continuation == nil { await Task.yield() }
        speech.finish("Find library")
        await retry.value
        while search.isSearching { await Task.yield() }
        #expect(await service.queries == ["library"])
    }

    @Test(.timeLimit(.minutes(1))) func cancellationRejectsLateExtraction() async {
        let speech = TestVoiceTranscriber()
        let extraction = ControlledVoiceExtractor()
        let service = VoiceSearchService()
        let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: extraction)
        let request = model.start(store: store(), search: SearchModel(service: service), latitude: 0, longitude: 0)
        while speech.continuation == nil { await Task.yield() }
        speech.finish("Find cafe")
        while extraction.continuation == nil { await Task.yield() }
        model.cancel()
        extraction.finish(VoiceCommand(destination: "cafe"))
        await request.value
        #expect(await service.queries.isEmpty)
        #expect(model.command == nil)
    }

    @Test(.timeLimit(.minutes(1))) func showsPermissionAndNoSpeechErrors() async {
        for error in [VoiceCommandError.microphoneDenied, .noSpeech, .unavailableLanguage, .downloadFailed] {
            let speech = TestVoiceTranscriber()
            speech.immediateError = error
            let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: TestVoiceExtractor())
            await model.start(store: store(), search: SearchModel(), latitude: 0, longitude: 0).value
            #expect(model.errorMessage == error.localizedDescription)
            #expect(model.status == nil)
        }
    }

    @Test(.timeLimit(.minutes(1))) func rejectsMalformedExtraction() async {
        let speech = TestVoiceTranscriber()
        let extractor = ControlledVoiceExtractor()
        let service = VoiceSearchService()
        let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: extractor)
        let task = model.start(store: store(), search: SearchModel(service: service), latitude: 0, longitude: 0)
        while speech.continuation == nil { await Task.yield() }
        speech.finish("Find cafe")
        while extractor.continuation == nil { await Task.yield() }
        extractor.finish(VoiceCommand(destination: "   "))
        await task.value
        #expect(model.errorMessage != nil)
        #expect(await service.queries.isEmpty)
    }

    @Test(.timeLimit(.minutes(1))) func broadSavedMatchesJoinOnlineResultsWithoutAutoSelection() async {
        let file = URL.temporaryDirectory.appending(path: "voice-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let saved = SavedPlacesStore(fileURL: file)
        let first = Place(id: "one", name: "North Tennis Club", address: "", latitude: 43, longitude: -79)
        let second = Place(id: "two", name: "South Tennis Club", address: "", latitude: 44, longitude: -79)
        saved.toggle(first); saved.toggle(second)
        let speech = TestVoiceTranscriber()
        let service = VoiceSearchService()
        let model = VoiceCommandModel(makeTranscriber: { speech }, extractor: TestVoiceExtractor())
        let search = SearchModel(service: service)
        let task = model.start(store: saved, search: search, latitude: 43, longitude: -79)
        while speech.continuation == nil { await Task.yield() }
        speech.finish("directions to tennis club")
        await task.value
        while search.isSearching { await Task.yield() }
        #expect(Set(search.results.map(\.id)).isSuperset(of: [first.id, second.id]))
        #expect(model.selection == nil)
        #expect(model.command?.action == .directions)
        #expect(await service.queries == ["tennis club"])
    }

}
