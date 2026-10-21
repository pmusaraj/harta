import Foundation

enum SavedPlaceIcon: String, CaseIterable, Identifiable, Sendable {
    case bookmark, home, work, favorite, cafe, restaurant, shopping, gym, park, parking, school, travel

    case tennis, soccer, basketball, baseball, football, hockey, golf, swimming, volleyball, badminton, pickleball, cricket, rugby

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bookmark: "Bookmark"
        case .home: "Home"
        case .work: "Work"
        case .favorite: "Favorite"
        case .cafe: "Café"
        case .restaurant: "Restaurant"
        case .shopping: "Shopping"
        case .gym: "Gym"
        case .park: "Park"
        case .parking: "Parking"
        case .school: "School"
        case .travel: "Travel"
        case .tennis: "Tennis"
        case .soccer: "Soccer"
        case .basketball: "Basketball"
        case .baseball: "Baseball"
        case .football: "American football"
        case .hockey: "Hockey"
        case .golf: "Golf"
        case .swimming: "Swimming"
        case .volleyball: "Volleyball"
        case .badminton: "Badminton"
        case .pickleball: "Pickleball"
        case .cricket: "Cricket"
        case .rugby: "Rugby"
        }
    }

    var symbol: String {
        switch self {
        case .bookmark: "bookmark.fill"
        case .home: "house.fill"
        case .work: "briefcase.fill"
        case .favorite: "star.fill"
        case .cafe: "cup.and.saucer.fill"
        case .restaurant: "fork.knife"
        case .shopping: "bag.fill"
        case .gym: "dumbbell.fill"
        case .park: "tree.fill"
        case .parking: "parkingsign"
        case .school: "graduationcap.fill"
        case .travel: "airplane"
        case .tennis: "tennisball.fill"
        case .soccer: "soccerball"
        case .basketball: "basketball.fill"
        case .baseball: "baseball.fill"
        case .football: "american.football.fill"
        case .hockey: "figure.hockey"
        case .golf: "figure.golf"
        case .swimming: "figure.pool.swim"
        case .volleyball: "volleyball.fill"
        case .badminton: "figure.badminton"
        case .pickleball: "figure.pickleball"
        case .cricket: "figure.cricket"
        case .rugby: "figure.rugby"
        }
    }


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
