import Foundation

struct PhotonResponse: Decodable {
    let features: [Feature]

    struct Feature: Decodable {
        let geometry: Geometry
        let properties: Properties
    }

    struct Geometry: Decodable {
        let type: String
        let coordinates: [Double]
    }

    struct Properties: Decodable {
        let name: String?
        let street: String?
        let housenumber: String?
        let city: String?
        let state: String?
        let country: String?
        let osm_id: Int64?
        let osm_type: String?
    }

    var places: [Place] {
        var seen = Set<String>()
        return features.compactMap { feature in
            let coordinates = feature.geometry.coordinates
            guard feature.geometry.type == "Point", coordinates.count >= 2,
                  coordinates[0].isFinite, coordinates[1].isFinite,
                  (-180...180).contains(coordinates[0]), (-90...90).contains(coordinates[1]) else {
                return nil
            }
            let properties = feature.properties
            let street = [properties.housenumber, properties.street]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            let name = [properties.name, street.isEmpty ? nil : street, properties.city, properties.country]
                .compactMap { $0 }.first(where: { !$0.isEmpty }) ?? "Unnamed place"
            let address = [street.isEmpty ? nil : street, properties.city, properties.state, properties.country]
                .compactMap { $0 }.filter { !$0.isEmpty && $0 != name }.joined(separator: ", ")
            let id: String
            if let osmID = properties.osm_id, let osmType = properties.osm_type {
                id = "osm:\(osmType):\(osmID)"
            } else {
                id = "coordinate:\(coordinates[1]):\(coordinates[0]):\(name)"
            }
            guard seen.insert(id).inserted else { return nil }
            return Place(id: id, name: name, address: address,
                         latitude: coordinates[1], longitude: coordinates[0])
        }
    }
}
