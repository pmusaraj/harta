import Foundation
@testable import Harta

@MainActor
final class TestVoiceTranscriber: VoiceTranscribing {
    var continuation: CheckedContinuation<String, Error>?
    var stopped = false
    var cancelled = false
    var immediateError: Error?

    func transcribe(status: @escaping @MainActor @Sendable (VoiceCaptureStatus) -> Void) async throws -> String {
        if let immediateError { throw immediateError }
        status(.listening)
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }
    func finish(_ text: String) {
        continuation?.resume(returning: text)
        continuation = nil
    }
    func stop() { stopped = true }
    // Intentionally keep a pending result to test rejection of late completions.
    func cancel() { cancelled = true }
}

@MainActor
struct TestVoiceExtractor: VoiceCommandExtracting {
    func extract(_ utterance: String) async throws -> VoiceCommand {
        try BasicVoiceCommandParser.parse(utterance)
    }
}

@MainActor
final class ControlledVoiceExtractor: VoiceCommandExtracting {
    var continuation: CheckedContinuation<VoiceCommand, Never>?
    func extract(_ utterance: String) async throws -> VoiceCommand {
        await withCheckedContinuation { continuation = $0 }
    }
    func finish(_ command: VoiceCommand) {
        continuation?.resume(returning: command)
        continuation = nil
    }
}

actor VoiceSearchService: PlaceSearching {
    private(set) var queries: [String] = []
    func search(query: String, latitude: Double?, longitude: Double?) async throws -> [Place] {
        queries.append(query)
        return [Place(id: "found", name: query, address: "", latitude: latitude ?? 0, longitude: longitude ?? 0)]
    }
}
