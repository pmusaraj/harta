import Foundation
import FerrostarCore

struct NavigationTestNetwork: URLRequestLoading {
    func loadData(with urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}
