import Foundation

/// Reads our bundled metadata, never private OS catalogs. Availability is checked by UIImage.
actor SymbolCatalog {
    static let shared = SymbolCatalog()
    private var entries: [Entry]?

    private struct Entry {
        let icon: SavedPlaceIcon
        let searchText: String
    }

    func matching(_ query: String) throws -> [SavedPlaceIcon] {
        if entries == nil {
            guard let url = Bundle.main.url(forResource: "SymbolCatalog", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            let metadata = try JSONDecoder().decode([String: [String]].self, from: Data(contentsOf: url))
            var loaded: [Entry] = []
            var seen = Set<String>()
            // Keep familiar place categories at the top, followed by the full catalog.
            let names = SavedPlaceIcon.allCases.map(\.symbol) + metadata.keys.sorted()
            for name in names {
                try Task.checkCancellation()
                guard seen.insert(name).inserted, let icon = SavedPlaceIcon(systemName: name) else { continue }
                let text = ([name, icon.title] + (metadata[name] ?? [])).joined(separator: " ")
                loaded.append(Entry(icon: icon, searchText: Self.normalized(text)))
            }
            entries = loaded
        }
        let tokens = Self.normalized(query).split(whereSeparator: \.isWhitespace)
        return entries?.filter { entry in tokens.allSatisfy { entry.searchText.contains($0) } }.map(\.icon) ?? []
    }

    static func matches(_ query: String, text: String) -> Bool {
        let tokens = normalized(query).split(whereSeparator: \.isWhitespace)
        let normalizedText = normalized(text)
        return tokens.allSatisfy { normalizedText.contains($0) }
    }

    private static func normalized(_ text: String) -> String {
        text.replacingOccurrences(of: ".", with: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
