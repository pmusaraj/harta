import AVFoundation
import Foundation
import Speech

/// One instance per utterance: an old cancelled request cannot tear down a new capture.
@MainActor
final class AppleSpeechTranscriber: VoiceTranscribing {
    private let engine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var input: AsyncThrowingStream<AnalyzerInput, Error>.Continuation?
    private var stopped: CheckedContinuation<Void, Never>?
    private var cancelled = false
    private var tapInstalled = false
    private var sessionActive = false
    private var downloadProgress: Progress?
    private var lastSpeech: Date?
    private var failure: Error?

    func transcribe(status: @escaping @MainActor @Sendable (VoiceCaptureStatus) -> Void) async throws -> String {
        status(.preparing)
        guard await AVAudioApplication.requestRecordPermission() else { throw VoiceCommandError.microphoneDenied }
        try checkCancellation()
        let locale = Locale.current
        let module: any SpeechModule
        let collect: @MainActor () async throws -> String
        if SpeechTranscriber.isAvailable, let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) {
            let transcriber = SpeechTranscriber(locale: supported, preset: .progressiveTranscription)
            module = transcriber
            collect = { [weak self] in
                var text = ""
                for try await result in transcriber.results {
                    if !result.text.characters.isEmpty { self?.lastSpeech = .now }
                    if result.isFinal { text += String(result.text.characters) + " " }
                }
                return text
            }
        } else if let supported = await DictationTranscriber.supportedLocale(equivalentTo: locale) {
            let transcriber = DictationTranscriber(locale: supported, preset: .progressiveShortDictation)
            module = transcriber
            collect = { [weak self] in
                var text = ""
                for try await result in transcriber.results {
                    if !result.text.characters.isEmpty { self?.lastSpeech = .now }
                    if result.isFinal { text += String(result.text.characters) + " " }
                }
                return text
            }
        } else {
            throw VoiceCommandError.unavailableLanguage
        }
        try checkCancellation()
        let detector = SpeechDetector(detectionOptions: .init(sensitivityLevel: .medium), reportResults: true)
        let modules: [any SpeechModule] = [module, detector]
        if let download = try await AssetInventory.assetInstallationRequest(supporting: modules) {
            downloadProgress = download.progress
            status(.downloading(0))
            let progressTask = Task {
                while !Task.isCancelled {
                    status(.downloading(download.progress.fractionCompleted))
                    try await Task.sleep(for: .milliseconds(250))
                }
            }
            defer { progressTask.cancel(); downloadProgress = nil }
            do { try await download.downloadAndInstall() }
            catch {
                try checkCancellation()
                throw VoiceCommandError.downloadFailed
            }
        }
        try checkCancellation()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [])
        try session.setActive(true)
        sessionActive = true
        defer { stopCapture() }
        let nativeFormat = engine.inputNode.outputFormat(forBus: 0)
        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0,
              let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules, considering: nativeFormat) else {
            throw VoiceCommandError.audioUnavailable
        }
        try checkCancellation()
        let analyzer = SpeechAnalyzer(modules: modules)
        self.analyzer = analyzer
        defer { Task { await analyzer.cancelAndFinishNow() } }
        try await analyzer.prepareToAnalyze(in: format)
        try checkCancellation()
        let resultTask = Task { try await collect() }
        let detectorTask = Task { [weak self] in
            for try await result in detector.results {
                if result.speechDetected { self?.lastSpeech = .now }
            }
        }
        defer { resultTask.cancel(); detectorTask.cancel() }
        let stream = AsyncThrowingStream<AnalyzerInput, Error>.makeStream(bufferingPolicy: .bufferingOldest(64))
        input = stream.continuation
        let converter = try SpeechAudioConverter(from: nativeFormat, to: format)
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: nativeFormat,
                                    block: converter.makeTap(continuation: stream.continuation))
        tapInstalled = true
        try await analyzer.start(inputSequence: stream.stream)
        try checkCancellation()
        engine.prepare()
        try engine.start()
        status(.listening)
        let start = Date.now
        let timer = Task { [weak self] in
            while !Task.isCancelled {
                try await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                let elapsed = Date.now.timeIntervalSince(start)
                if elapsed >= 20 || (lastSpeech == nil && elapsed >= 8) ||
                    (lastSpeech.map { Date.now.timeIntervalSince($0) >= 0.8 } ?? false) {
                    stop()
                    return
                }
            }
        }
        let interruptions = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification) {
                guard !Task.isCancelled else { return }
                self?.failure = VoiceCommandError.interrupted
                self?.stop()
            }
        }
        let routeChanges = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: AVAudioSession.routeChangeNotification) {
                guard !Task.isCancelled else { return }
                self?.failure = VoiceCommandError.interrupted
                self?.stop()
            }
        }
        defer { timer.cancel(); interruptions.cancel(); routeChanges.cancel() }
        await withCheckedContinuation { stopped = $0 }
        timer.cancel(); interruptions.cancel(); routeChanges.cancel()
        try checkCancellation()
        if let failure { throw failure }
        status(.processing)
        let watchdog = Task { [weak self] in
            try await Task.sleep(for: .seconds(15))
            self?.failure = VoiceCommandError.timedOut
            await analyzer.cancelAndFinishNow()
        }
        defer { watchdog.cancel() }
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        let text = try await resultTask.value.trimmingCharacters(in: .whitespacesAndNewlines)
        try checkCancellation()
        if let failure { throw failure }
        guard !text.isEmpty else { throw VoiceCommandError.noSpeech }
        return text
    }

    func stop() {
        stopCapture()
        stopped?.resume()
        stopped = nil
    }

    func cancel() {
        cancelled = true
        downloadProgress?.cancel()
        stop()
        if let analyzer { Task { await analyzer.cancelAndFinishNow() } }
    }

    private func checkCancellation() throws {
        try Task.checkCancellation()
        if cancelled { throw CancellationError() }
    }

    private func stopCapture() {
        engine.stop()
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        input?.finish()
        input = nil
        if sessionActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            sessionActive = false
        }
    }
}
