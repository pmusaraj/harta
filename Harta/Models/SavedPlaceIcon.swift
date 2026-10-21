enum SavedPlaceIcon: String, CaseIterable, Identifiable, Sendable {
    case bookmark, home, work, favorite, cafe, restaurant, shopping, gym, park, parking, school, travel

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
        }
    }
}
