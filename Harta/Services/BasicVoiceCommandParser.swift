import Foundation

/// A conservative offline fallback and a fast path for explicit English commands.
struct BasicVoiceCommandParser {
    static func parse(_ utterance: String) throws -> VoiceCommand {
        var text = utterance.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !text.isEmpty else { throw VoiceCommandError.noSpeech }
        let normalized = " " + VoiceCommand.normalized(text) + " "
        let filters = ["open now", "open late", "rating", "ratings", "rated", "cheapest", "under", "wheelchair", "available", "availability", "within", "stars"]
        if filters.contains(where: { normalized.contains(" " + $0 + " ") }) || text.contains("$") {
            throw VoiceCommandError.unsupportedFilters
        }
        if text.lowercased().hasPrefix("please ") { text = String(text.dropFirst(7)) }
        var command = VoiceCommand(destination: text)
        let prefixes: [(String, VoiceCommand.Action, TravelMode?)] = [
            ("walking directions to ", .directions, .walking),
            ("cycling directions to ", .directions, .cycling),
            ("driving directions to ", .directions, .driving),
            ("give me directions to ", .directions, nil),
            ("directions to ", .directions, nil), ("directions ", .directions, nil),
            ("navigate to ", .directions, nil), ("take me to ", .directions, nil),
            ("go to ", .directions, nil), ("go ", .directions, nil),
            ("walk to ", .directions, .walking), ("walk ", .directions, .walking),
            ("cycle to ", .directions, .cycling), ("bike to ", .directions, .cycling),
            ("drive to ", .directions, .driving), ("drive ", .directions, .driving),
            ("search for ", .search, nil), ("find ", .search, nil), ("search ", .search, nil)
        ]
        if prefixes.contains(where: { text.lowercased() == $0.0.trimmingCharacters(in: .whitespaces) }) {
            throw VoiceCommandError.missingDestination
        }
        if let prefix = prefixes.first(where: { text.lowercased().hasPrefix($0.0) }) {
            text = String(text.dropFirst(prefix.0.count))
            command.action = prefix.1
            command.mode = prefix.2
        }
        for (suffix, mode) in [(" on foot", TravelMode.walking), (" by bike", .cycling), (" by bicycle", .cycling), (" by car", .driving)] {
            if text.lowercased().hasSuffix(suffix) {
                text = String(text.dropLast(suffix.count))
                command.mode = mode
                command.action = .directions
                break
            }
        }
        let request = PlaceSearchRequest(text: text)
        command.destination = request.destination
        command.locality = request.locality
        command.area = request.area
        guard !command.destination.isEmpty,
              !["find", "search", "directions", "go", "navigate"].contains(VoiceCommand.normalized(command.destination)) else {
            throw VoiceCommandError.missingDestination
        }
        return command
    }
}
