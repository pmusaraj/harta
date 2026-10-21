import Foundation

enum VoiceCaptureStatus: Equatable, Sendable {
    case preparing, downloading(Double), listening, processing

    var message: String {
        switch self {
        case .preparing: "Preparing microphone…"
        case .downloading(let progress): "Downloading speech support… \(Int(progress * 100))%"
        case .listening: "Listening…"
        case .processing: "Processing…"
        }
    }
}

@MainActor
protocol VoiceTranscribing: AnyObject {
    func transcribe(status: @escaping @MainActor @Sendable (VoiceCaptureStatus) -> Void) async throws -> String
    func stop()
    func cancel()
}
