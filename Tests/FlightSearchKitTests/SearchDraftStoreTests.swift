import Foundation
import Testing
@testable import FlightSearchKit

@MainActor
struct SearchDraftStoreTests {
    @Test func aNewStoreLoadsAnEmptyDraft() throws {
        let store = CoreDataSearchDraftStore(location: .inMemory)
        #expect(try store.load() == .empty)
    }

    @Test func saveReplacesThePreviousDraft() throws {
        let store = CoreDataSearchDraftStore(location: .inMemory)
        try store.save(SearchDraft(tripType: .oneWay, originCode: "DXB", destinationCode: "LHR"))
        try store.save(SearchDraft(tripType: .multiCity, originCode: "BOM", destinationCode: "DEL"))
        #expect(try store.load() == SearchDraft(tripType: .multiCity, originCode: "BOM", destinationCode: "DEL"))
    }

    @Test func aNewContainerReadsTheSavedFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlightSearchKitTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("SearchDraft.sqlite")
        let first = CoreDataSearchDraftStore(location: .file(url))
        let draft = SearchDraft(tripType: .roundTrip, originCode: "SIN", destinationCode: "SYD")
        try first.save(draft)

        let second = CoreDataSearchDraftStore(location: .file(url))
        #expect(try second.load() == draft)
        #expect(TripType.stored("return") == .roundTrip)
        #expect(TripType.stored("unknown") == .oneWay)
    }

    @Test func inMemoryStoresDoNotShareDrafts() throws {
        let first = CoreDataSearchDraftStore(location: .inMemory)
        let second = CoreDataSearchDraftStore(location: .inMemory)
        try first.save(SearchDraft(tripType: .oneWay, originCode: "JFK", destinationCode: "LAX"))
        #expect(try second.load() == .empty)
    }
}
