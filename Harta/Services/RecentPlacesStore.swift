import Foundation
import Observation

@MainActor @Observable
final class RecentPlacesStore {
    private(set) var places: [Place] = []
    private let defaults: UserDefaults
    private let key = "recentPlaces"
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        reload()
    }
    func reload() {
        places = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([Place].self, from: $0) } ?? []
    }
    func record(_ place: Place) {
        places.removeAll { $0.id == place.id }
        places.insert(place, at: 0)
        places = Array(places.prefix(10))
        if let data = try? JSONEncoder().encode(places) { defaults.set(data, forKey: key) }
    }
    func clear() { places = []; defaults.removeObject(forKey: key) }
}
