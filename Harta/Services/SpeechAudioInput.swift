import AVFoundation
import Foundation

/// AVAudioConverter invokes its input block synchronously, but declares it Sendable.
/// Protect the one-shot buffer handoff explicitly instead of capturing mutable state.
final class SpeechAudioInput: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: AVAudioPCMBuffer?

    init(buffer: AVAudioPCMBuffer) { self.buffer = buffer }

    func take(status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        lock.lock()
        defer { lock.unlock() }
        guard let buffer else { status.pointee = .noDataNow; return nil }
        self.buffer = nil
        status.pointee = .haveData
        return buffer
    }
}
