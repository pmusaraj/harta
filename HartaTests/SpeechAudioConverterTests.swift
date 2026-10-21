import AVFoundation
import Testing
import Speech
@testable import Harta

struct SpeechAudioConverterTests {
    @Test func resamplesAndOwnsOutputBuffers() throws {
        let inputFormat = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let outputFormat = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let input = try #require(AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: 4800))
        input.frameLength = 4800
        let channel = try #require(input.floatChannelData?[0])
        for index in 0..<4800 { channel[index] = 0.25 }
        let converter = try SpeechAudioConverter(from: inputFormat, to: outputFormat)
        let first = try converter.convert(input).buffer
        #expect(first.format.sampleRate == 16_000)
        #expect(first.frameLength > 0 && first.frameLength <= 1632)
        let firstChannel = try #require(first.floatChannelData?[0])
        let savedSample = firstChannel[Int(first.frameLength) / 2]
        for index in 0..<4800 { channel[index] = -0.5 }
        let second = try converter.convert(input).buffer
        #expect(first !== second)
        #expect(firstChannel[Int(first.frameLength) / 2] == savedSample)
        #expect(savedSample > 0)
    }

    @MainActor @Test(.timeLimit(.minutes(1)))
    func audioTapCreatedFromUIRunsOffMainActor() async throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let converter = try SpeechAudioConverter(from: format, to: format)
        let stream = AsyncThrowingStream<AnalyzerInput, Error>.makeStream()
        let tap = converter.makeTap(continuation: stream.continuation)
        // Mirrors AVAudioEngine invoking a callback installed by the main-actor service.
        try await Task.detached {
            let inputFormat = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
            let input = try #require(AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: 1024))
            input.frameLength = 1024
            let channel = try #require(input.floatChannelData?[0])
            for index in 0..<1024 { channel[index] = 0.25 }
            tap(input, AVAudioTime(sampleTime: 0, atRate: 16_000))
            stream.continuation.finish()
        }.value
        var iterator = stream.stream.makeAsyncIterator()
        let result = try #require(try await iterator.next())
        #expect(result.buffer.frameLength > 0)
    }

}
