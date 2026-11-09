import Foundation

struct StadiaResponse: Decodable {
    let features: [Feature]
    struct Feature: Decodable {
        let geometry: Geometry?
        let properties: Properties
    }
    struct Geometry: Decodable {
        let type: String
        let coordinates: [Double]
    }
    struct Properties: Decodable {
        let gid: String
        let name: String
        let coarse_location: String?
        let formatted_address_line: String?
    }
    var suggestions: [PlaceSuggestion] {
        var seen = Set<String>()
        return features.compactMap {
            let p = $0.properties
            guard !p.gid.isEmpty, seen.insert(p.gid).inserted else { return nil }
            return PlaceSuggestion(id: p.gid, name: p.name, address: p.coarse_location ?? "")
        }
    }
    var places: [Place] {
        var seen = Set<String>()
        return features.compactMap {
            guard let geometry = $0.geometry, geometry.type == "Point", geometry.coordinates.count >= 2 else { return nil }
            let lon = geometry.coordinates[0], lat = geometry.coordinates[1], p = $0.properties
            guard lon.isFinite, lat.isFinite, (-180...180).contains(lon), (-90...90).contains(lat),
                  !p.gid.isEmpty, seen.insert(p.gid).inserted else { return nil }
            return Place(id: p.gid, name: p.name, address: p.formatted_address_line ?? p.coarse_location ?? "",
                         latitude: lat, longitude: lon)
        }
    }
}
