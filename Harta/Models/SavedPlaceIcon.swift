import Foundation
import UIKit

/// Preset IDs remain compatible with existing saves; custom symbols use a namespace.
struct SavedPlaceIcon: RawRepresentable, CaseIterable, Identifiable, Hashable, Sendable {
    let rawValue: String
    var id: String { rawValue }

    private init(preset: String) { rawValue = preset }

    init?(rawValue: String) {
        if Self.presets[rawValue] != nil {
            self.rawValue = rawValue
        } else if rawValue.hasPrefix("symbol:"),
                  UIImage(systemName: String(rawValue.dropFirst(7))) != nil {
            self.rawValue = rawValue
        } else { return nil }
    }

    init?(systemName: String) {
        if let preset = Self.allCases.first(where: { $0.symbol == systemName }) {
            self = preset
        } else {
            self.init(rawValue: "symbol:" + systemName)
        }
    }

    var title: String {
        Self.presets[rawValue]?.title ?? symbol.replacingOccurrences(of: ".", with: " ").capitalized
    }
    var symbol: String { Self.presets[rawValue]?.symbol ?? String(rawValue.dropFirst(7)) }

    static let bookmark = Self(preset: "bookmark")
    static let home = Self(preset: "home")
    static let work = Self(preset: "work")
    static let favorite = Self(preset: "favorite")
    static let cafe = Self(preset: "cafe")
    static let restaurant = Self(preset: "restaurant")
    static let shopping = Self(preset: "shopping")
    static let gym = Self(preset: "gym")
    static let park = Self(preset: "park")
    static let parking = Self(preset: "parking")
    static let school = Self(preset: "school")
    static let travel = Self(preset: "travel")
    static let tennis = Self(preset: "tennis")
    static let soccer = Self(preset: "soccer")
    static let basketball = Self(preset: "basketball")
    static let baseball = Self(preset: "baseball")
    static let football = Self(preset: "football")
    static let hockey = Self(preset: "hockey")
    static let golf = Self(preset: "golf")
    static let swimming = Self(preset: "swimming")
    static let volleyball = Self(preset: "volleyball")
    static let badminton = Self(preset: "badminton")
    static let pickleball = Self(preset: "pickleball")
    static let cricket = Self(preset: "cricket")
    static let rugby = Self(preset: "rugby")

    static let allCases: [Self] = [.bookmark, .home, .work, .favorite, .cafe, .restaurant, .shopping, .gym, .park, .parking, .school, .travel, .tennis, .soccer, .basketball, .baseball, .football, .hockey, .golf, .swimming, .volleyball, .badminton, .pickleball, .cricket, .rugby]

    private static let presets: [String: (title: String, symbol: String)] = [
        "bookmark": ("Bookmark", "bookmark.fill"),
        "home": ("Home", "house.fill"),
        "work": ("Work", "briefcase.fill"),
        "favorite": ("Favorite", "star.fill"),
        "cafe": ("Café", "cup.and.saucer.fill"),
        "restaurant": ("Restaurant", "fork.knife"),
        "shopping": ("Shopping", "bag.fill"),
        "gym": ("Gym", "dumbbell.fill"),
        "park": ("Park", "tree.fill"),
        "parking": ("Parking", "parkingsign"),
        "school": ("School", "graduationcap.fill"),
        "travel": ("Travel", "airplane"),
        "tennis": ("Tennis", "tennisball.fill"),
        "soccer": ("Soccer", "soccerball"),
        "basketball": ("Basketball", "basketball.fill"),
        "baseball": ("Baseball", "baseball.fill"),
        "football": ("American football", "american.football.fill"),
        "hockey": ("Hockey", "figure.hockey"),
        "golf": ("Golf", "figure.golf"),
        "swimming": ("Swimming", "figure.pool.swim"),
        "volleyball": ("Volleyball", "volleyball.fill"),
        "badminton": ("Badminton", "figure.badminton"),
        "pickleball": ("Pickleball", "figure.pickleball"),
        "cricket": ("Cricket", "figure.cricket"),
        "rugby": ("Rugby", "figure.rugby")
    ]

    /// Match whole words in the venue name, never its address or partial words.
    /// Specific compound sports take precedence over their generic components.
    static func detected(in name: String) -> SavedPlaceIcon? {
        let words = name.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                 locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let normalized = " " + words.joined(separator: " ") + " "
        let matches: [(SavedPlaceIcon, [String])] = [
            (.football, ["american football", "football americain", "gridiron"]),
            (.pickleball, ["pickleball"]),
            (.badminton, ["badminton"]),
            (.tennis, ["tennis"]),
            (.basketball, ["basketball", "basket ball"]),
            (.soccer, ["soccer", "football", "futbol", "futsal"]),
            (.baseball, ["baseball", "base ball", "softball"]),
            (.hockey, ["hockey"]),
            (.golf, ["golf"]),
            (.swimming, ["swimming", "swim", "aquatic", "aquatics", "piscine", "natation"]),
            (.volleyball, ["volleyball", "volley ball"]),
            (.cricket, ["cricket"]),
            (.rugby, ["rugby"])
        ]
        return matches.first { _, keywords in
            keywords.contains { normalized.contains(" " + $0 + " ") }
        }?.0
    }
}
