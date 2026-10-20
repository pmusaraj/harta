import Foundation
import Testing
@testable import Harta

@MainActor
struct SearchModelTests {
    @Test(.timeLimit(.minutes(1))) func ignoresResultsAfterQueryChanges() async {
        let service = ControlledSearchService()
        let model = SearchModel(service: service)
        model.query = "Toronto"
        let request = model.submit(latitude: 43, longitude: -79)
        while !(await service.hasPendingRequest) { await Task.yield() }
        model.query = "Montreal"
        model.queryChanged()
        await service.finish()
        await request?.value
        #expect(model.results.isEmpty)
        #expect(!model.isSearching)
        #expect(!model.hasSearched)
    }

    @Test(.timeLimit(.minutes(1))) func publishesSuccessfulResults() async {
        let service = ControlledSearchService()
        let model = SearchModel(service: service)
        model.query = "Toronto"
        let request = model.submit(latitude: 43, longitude: -79)
        while !(await service.hasPendingRequest) { await Task.yield() }
        await service.finish()
        await request?.value
        #expect(model.results.first?.name == "Toronto")
        #expect(model.errorMessage == nil)
    }
}
