import Foundation
@preconcurrency import FerrostarCore

actor NavigationNetwork: URLRequestLoading {
    private var nextRequest = Date.distantPast
    let onError: @MainActor @Sendable () -> Void
    init(onError: @escaping @MainActor @Sendable () -> Void) { self.onError = onError }
    func loadData(with urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        let delay = max(0, nextRequest.timeIntervalSinceNow)
        nextRequest = Date().addingTimeInterval(delay + 2)
        try await Task.sleep(for: .seconds(delay))
        try Task.checkCancellation()
        var request = urlRequest
        request.timeoutInterval = 25
        request.setValue("com.musaraj.harta", forHTTPHeaderField: "X-Client-Id")
        request.setValue("Harta-iOS/0.1", forHTTPHeaderField: "User-Agent")
        do {
            let result = try await URLSession.shared.data(for: request)
            guard let response = result.1 as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return result
        } catch {
            if !Task.isCancelled { await onError() }
            throw error
        }
    }
}
