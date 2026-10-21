import Foundation

enum VoiceCommandError: LocalizedError {
    case noSpeech, missingDestination, unsupportedFilters, microphoneDenied, unavailableLanguage, audioUnavailable, interrupted, timedOut, downloadFailed

    var errorDescription: String? {
        switch self {
        case .downloadFailed: "Speech support couldn’t be downloaded. Check your connection and try again."
        case .noSpeech: "No speech detected. Try again or type a place name."
        case .missingDestination: "Say a destination, such as ‘find tennis clubs’ or ‘go home’."
        case .unsupportedFilters: "Voice search supports place names and addresses, but not filters such as opening hours, ratings, or prices. Try a simpler search."
        case .microphoneDenied: "Allow microphone access for Harta in Settings, or type your search."
        case .unavailableLanguage: "On-device speech recognition isn’t available for your device language. You can still type a search."
        case .audioUnavailable: "The microphone is unavailable. Try again or type your search."
        case .interrupted: "Voice search was interrupted. Tap the microphone to try again."
        case .timedOut: "Voice search took too long. Try again or type your search."
        }
    }
}
