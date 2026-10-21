import Foundation

@MainActor
protocol VoiceCommandExtracting {
    func extract(_ utterance: String) async throws -> VoiceCommand
}

