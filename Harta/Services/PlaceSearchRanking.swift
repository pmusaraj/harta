import CoreLocation
import Foundation

struct PlaceSearchRanking {
    static func tokens(_ text: String) -> [String] {
        VoiceCommand.normalized(text).split(separator: " ").map { word in
            let word = String(word)
            if ["cafes", "coffee", "coffees"].contains(word) { return "cafe" }
            if word == "centre" { return "center" }
            if word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss"), word != "tennis" {
                return String(word.dropLast())
            }
            return word
        }
    }

    static func category(for query: String) -> SavedPlaceIcon? {
        let words = tokens(query)
        if words == ["pool"] { return .swimming }
        let fillers: Set<String> = ["a", "the", "club", "court", "center", "venue", "place", "pool", "field", "course"]
        let subject = words.filter { !fillers.contains($0) }.joined(separator: " ")
        // A proper name such as Riverside Tennis Club must not match every tennis venue.
        if let sport = SavedPlaceIcon.detected(in: subject),
           subject == sport.rawValue || subject == "american football" || subject == "futbol" {
            return sport
        }
        return switch subject {
        case "cafe": .cafe
        case "restaurant", "food": .restaurant
        case "gym", "fitness": .gym
        case "park": .park
        case "parking": .parking
        case "shopping", "shop": .shopping
        case "swim", "swimming", "piscine": .swimming
        default: nil
        }
    }

    static func relevance(_ place: Place, request: PlaceSearchRequest) -> Double {
        if let locality = request.locality, !locality.isEmpty {
            let locationWords = tokens(place.address + " " + place.name)
            guard tokens(locality).allSatisfy(locationWords.contains) else { return 0 }
        }
        let query = tokens(request.destination)
        let name = tokens(place.name)
        guard !query.isEmpty else { return 0 }
        if query == name { return category(for: request.destination) == nil ? 100 : 80 }
        if let category = category(for: request.destination), place.icon == category { return 80 }
        if query.allSatisfy(name.contains) { return 85 }
        if query.allSatisfy({ word in name.contains { similar(word, $0) } }) { return 70 }
        return 0
    }

    /// One insertion, deletion, substitution or adjacent transposition in words of 5+ letters.
    private static func similar(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == rhs { return true }
        guard min(lhs.count, rhs.count) >= 5, abs(lhs.count - rhs.count) <= 1 else { return false }
        let a = Array(lhs), b = Array(rhs)
        if a.count == b.count {
            let differences = a.indices.filter { a[$0] != b[$0] }
            if differences.count == 1 { return true }
            if differences.count == 2 {
                let i = differences[0], j = differences[1]
                return j == i + 1 && a[i] == b[j] && a[j] == b[i]
            }
            return false
        }
        let shorter = a.count < b.count ? a : b
        let longer = a.count < b.count ? b : a
        var i = 0, j = 0, skipped = false
        while i < shorter.count && j < longer.count {
            if shorter[i] == longer[j] { i += 1; j += 1 }
            else if !skipped { skipped = true; j += 1 }
            else { return false }
        }
        return true
    }

    static func merge(saved: [Place], online: [Place], request: PlaceSearchRequest,
                      latitude: Double?, longitude: Double?) -> [Place] {
        let matched = saved.filter { relevance($0, request: request) > 0 }
        var combined = matched
        let savedByID = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for place in online {
            // Preserve saved coordinates and icon metadata when the provider returns that place.
            let candidate = savedByID[place.id] ?? saved.first(where: { duplicate($0, place) }) ?? place
            if !combined.contains(where: { duplicate($0, candidate) }) { combined.append(candidate) }
        }
        let savedIDs = Set(saved.map(\.id))
        let anchor: CLLocation? = if let latitude, let longitude, request.locality == nil {
            CLLocation(latitude: latitude, longitude: longitude)
        } else { nil }
        func score(_ place: Place) -> Double {
            let relevance = relevance(place, request: request)
            let distance = anchor.map {
                $0.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude)) / 1000
            } ?? 0
            let distancePenalty = relevance == 100 ? 0 : min(45, log2(1 + distance) * 6)
            return max(45, relevance) + (savedIDs.contains(place.id) ? 10 : 0) - distancePenalty
        }
        return combined.enumerated().sorted { lhs, rhs in
            let a = score(lhs.element), b = score(rhs.element)
            return a == b ? lhs.offset < rhs.offset : a > b
        }.map(\.element)
    }

    private static func duplicate(_ lhs: Place, _ rhs: Place) -> Bool {
        if lhs.id == rhs.id { return true }
        guard tokens(lhs.name) == tokens(rhs.name) else { return false }
        return CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)) < 50
    }
}
