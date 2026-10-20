import Foundation

struct MapRoute: Identifiable, Sendable {
    let id = UUID()
    let points: [Point]
    let steps: [Step]
    let seconds: Double
    let kilometers: Double
    var summary: String {
        "\(max(1, Int(ceil(seconds / 60)))) min · \(kilometers.formatted(.number.precision(.fractionLength(1)))) km"
    }
    struct Point: Equatable, Sendable { let latitude: Double; let longitude: Double }
    struct Step: Identifiable, Sendable {
        let id: Int
        let instruction: String
        let kilometers: Double
        let start: Int
        let end: Int
    }
}
