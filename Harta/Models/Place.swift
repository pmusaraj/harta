import CoreLocation
import Foundation

struct Place: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateLabel: String {
        let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(5))
        return "\(latitude.formatted(format)), \(longitude.formatted(format))"
    }

    var shareURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.openstreetmap.org"
        components.queryItems = [
            URLQueryItem(name: "mlat", value: String(latitude)),
            URLQueryItem(name: "mlon", value: String(longitude))
        ]
        components.fragment = "map=16/\(latitude)/\(longitude)"
        guard let url = components.url else { preconditionFailure("Invalid place sharing URL") }
        return url
    }

    static func pin(at coordinate: CLLocationCoordinate2D) -> Place {
        Place(id: "pin:\(coordinate.latitude):\(coordinate.longitude)", name: "Dropped pin",
              address: "", latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
