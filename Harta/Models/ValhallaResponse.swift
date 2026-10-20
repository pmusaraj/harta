import Foundation

struct ValhallaResponse: Decodable {
    let trip: Trip
    struct Trip: Decodable {
        let status: Int
        let summary: Summary
        let legs: [Leg]
    }
    struct Summary: Decodable { let time: Double; let length: Double }
    struct Leg: Decodable { let shape: String; let maneuvers: [Maneuver] }
    struct Maneuver: Decodable {
        let instruction: String
        let length: Double
        let begin_shape_index: Int
        let end_shape_index: Int
    }
    func route() throws -> MapRoute {
        guard trip.status == 0, trip.summary.time.isFinite, trip.summary.time >= 0,
              Int(exactly: ceil(trip.summary.time / 60)) != nil,
              trip.summary.length.isFinite, trip.summary.length >= 0 else { throw URLError(.cannotParseResponse) }
        var points: [MapRoute.Point] = []
        var steps: [MapRoute.Step] = []
        for leg in trip.legs {
            let decoded = try Self.decodePolyline(leg.shape)
            let offset = points.count
            for maneuver in leg.maneuvers {
                guard maneuver.begin_shape_index >= 0,
                      maneuver.length.isFinite, maneuver.length >= 0,
                      Int(exactly: (maneuver.length * 1000).rounded()) != nil,
                      maneuver.end_shape_index >= maneuver.begin_shape_index,
                      maneuver.end_shape_index < decoded.count else { throw URLError(.cannotParseResponse) }
                steps.append(.init(id: steps.count, instruction: maneuver.instruction,
                                   kilometers: maneuver.length, start: offset + maneuver.begin_shape_index,
                                   end: offset + maneuver.end_shape_index))
            }
            points.append(contentsOf: decoded)
        }
        guard points.count >= 2 else { throw URLError(.cannotParseResponse) }
        return MapRoute(points: points, steps: steps, seconds: trip.summary.time, kilometers: trip.summary.length)
    }
    static func decodePolyline(_ value: String) throws -> [MapRoute.Point] {
        let bytes = Array(value.utf8)
        var index = 0
        func component() throws -> Int64 {
            var result: Int64 = 0
            var shift = 0
            while index < bytes.count, shift <= 30 {
                let byte = Int(bytes[index]) - 63
                index += 1
                guard (0...63).contains(byte) else { throw URLError(.cannotParseResponse) }
                result |= Int64(byte & 31) << shift
                if byte < 32 { return result & 1 == 0 ? result >> 1 : ~(result >> 1) }
                shift += 5
            }
            throw URLError(.cannotParseResponse)
        }
        var lat: Int64 = 0
        var lon: Int64 = 0
        var points: [MapRoute.Point] = []
        while index < bytes.count {
            lat += try component(); lon += try component()
            let point = MapRoute.Point(latitude: Double(lat) / 1e6, longitude: Double(lon) / 1e6)
            guard abs(point.latitude) <= 90, abs(point.longitude) <= 180 else { throw URLError(.cannotParseResponse) }
            points.append(point)
        }
        return points
    }
}
