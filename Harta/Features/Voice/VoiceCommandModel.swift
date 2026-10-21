import Foundation
import Observation

@MainActor @Observable
final class VoiceCommandModel {
    struct Selection: Equatable {
        let place: Place
        let command: VoiceCommand
    }

    private(set) var status: VoiceCaptureStatus?
    private(set) var errorMessage: String?
    private(set) var candidates: [Place] = []
    private(set) var command: VoiceCommand?
    private(set) var selection: Selection?
    private let makeTranscriber: @MainActor () -> any VoiceTranscribing
    private let extractor: any VoiceCommandExtracting
    private var transcriber: (any VoiceTranscribing)?
    private var task: Task<Void, Never>?
    private var generation = UUID()

    init(makeTranscriber: @escaping @MainActor () -> any VoiceTranscribing = { AppleSpeechTranscriber() },
         extractor: any VoiceCommandExtracting = AppleVoiceCommandExtractor()) {
        self.makeTranscriber = makeTranscriber
        self.extractor = extractor
    }

    @discardableResult
    func start(store: SavedPlacesStore, search: SearchModel, latitude: Double, longitude: Double,
               currentLocation: @escaping @MainActor () -> LocationFix? = { nil }) -> Task<Void, Never> {
        cancel()
        search.queryChanged()
        let token = generation
        let transcriber = makeTranscriber()
        self.transcriber = transcriber
        status = .preparing
        let request = Task { [weak self, extractor] in
            guard let self else { return }
            do {
                let utterance = try await transcriber.transcribe { [weak self] status in
                    guard let self, generation == token else { return }
                    self.status = status
                }
                guard generation == token, !Task.isCancelled else { return }
                status = .processing
                let timeout = Task { [weak self] in
                    try await Task.sleep(for: .seconds(20))
                    guard let self, generation == token else { return }
                    cancel()
                    errorMessage = VoiceCommandError.timedOut.localizedDescription
                }
                defer { timeout.cancel() }
                let extracted = try await extractor.extract(utterance)
                guard generation == token, !Task.isCancelled else { return }
                guard !VoiceCommand.normalized(extracted.destination).isEmpty else { throw VoiceCommandError.missingDestination }
                command = extracted
                status = nil
                switch SavedPlaceResolver.resolve(extracted, places: store.places) {
                case .matches(let places):
                    if places.count == 1, let place = places.first {
                        selection = Selection(place: place, command: extracted)
                    } else { candidates = places }
                case .missingAlias(let alias):
                    errorMessage = "No saved \(alias) found. Save a place named \(alias), or choose its \(alias) icon."
                case .search:
                    search.submit(request: extracted.searchRequest, latitude: latitude, longitude: longitude,
                                  currentLocation: currentLocation(), savedPlaces: store.places)
                }
            } catch {
                guard generation == token, !Task.isCancelled else { return }
                status = nil
                errorMessage = (error as? VoiceCommandError)?.localizedDescription
                    ?? "Voice search couldn’t finish. Try again or type a place name."
            }
            if generation == token { self.transcriber = nil }
        }
        task = request
        return request
    }

    func stop() {
        guard status == .listening else { return }
        status = .processing
        transcriber?.stop()
    }

    func cancel() {
        generation = UUID()
        task?.cancel()
        task = nil
        transcriber?.cancel()
        transcriber = nil
        status = nil
        errorMessage = nil
        candidates = []
        command = nil
        selection = nil
    }
}
