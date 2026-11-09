import Foundation

enum StadiaServiceError: LocalizedError {
    case missingKey, unauthorized, quotaExceeded
    var errorDescription: String? {
        switch self {
        case .missingKey: "Online search and directions aren’t configured. Add a Stadia Maps API key to this build."
        case .unauthorized: "Stadia Maps rejected the API key or this service isn’t available on the account."
        case .quotaExceeded: "Stadia Maps’ usage limit has been reached. Please try again later."
        }
    }
    static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        switch http.statusCode {
        case 200..<300: return
        case 401, 403: throw Self.unauthorized
        case 429: throw Self.quotaExceeded
        default: throw URLError(.badServerResponse)
        }
    }
}
