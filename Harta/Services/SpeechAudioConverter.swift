import AVFoundation
import Foundation
import Speech

/// The audio tap owns conversion; the lock also protects against overlapping tap callbacks.
/// Each yielded buffer is newly allocated and never mutated after ownership is transferred.
final class SpeechAudioConverter: @unchecked Sendable {
    private let converter: AVAudioConverter
    private let format: AVAudioFormat
    private let lock = NSLock()

    init(from input: AVAudioFormat, to output: AVAudioFormat) throws {
        guard let converter = AVAudioConverter(from: input, to: output) else {
            throw VoiceCommandError.audioUnavailable
        }
        self.converter = converter
        self.format = output
    }

    /// Construct outside the UI actor: AVAudioEngine calls this on its audio thread.
    func makeTap(continuation: AsyncThrowingStream<AnalyzerInput, Error>.Continuation)
        -> @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void {
        { [self] buffer, _ in
            do {
                let value = try convert(buffer)
                if case .dropped = continuation.yield(value) {
                    continuation.finish(throwing: VoiceCommandError.audioUnavailable)
                }
            } catch { continuation.finish(throwing: error) }
        }
    }

    func convert(_ input: AVAudioPCMBuffer) throws -> AnalyzerInput {
        lock.lock()
        defer { lock.unlock() }
        let capacity = AVAudioFrameCount(ceil(Double(input.frameLength) * format.sampleRate / input.format.sampleRate)) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw VoiceCommandError.audioUnavailable
        }
        let source = SpeechAudioInput(buffer: input)
        var error: NSError?
        let result = converter.convert(to: output, error: &error) { _, status in
            source.take(status: status)
        }
        if let error { throw error }
        guard result != .error else { throw VoiceCommandError.audioUnavailable }
        return AnalyzerInput(buffer: output)
    }
}
