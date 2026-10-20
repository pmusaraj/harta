import CoreLocation
import Foundation

struct LocationFix: Equatable {
    let id = UUID()
    var timestamp = Date()
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
