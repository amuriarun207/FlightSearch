import Foundation
import Testing
@testable import FlightSearchKit

struct AirportFilteringTests {
    @Test func catalogContainsTheMilestoneAirports() {
        let codes = AirportCatalog.all.map(\.iataCode)
        #expect(codes == ["DXB", "LHR", "JFK", "BOM", "SIN", "DOH", "SYD", "FRA", "LAX", "DEL"])
    }

    @Test func airportIdentityUsesTheIATACode() throws {
        let dubai = try airport("DXB")
        #expect(dubai.id == "DXB")
        #expect(dubai.city == "Dubai")
    }

    @Test func emptyAndWhitespaceQueriesReturnEveryAirport() {
        #expect(AirportFiltering.filter(AirportCatalog.all, query: "").count == 10)
        #expect(AirportFiltering.filter(AirportCatalog.all, query: "   ") == AirportCatalog.all)
    }

    @Test func filtersByIATACodeIgnoringCase() throws {
        let heathrow = try airport("LHR")
        let results = AirportFiltering.filter(AirportCatalog.all, query: "lhr")
        #expect(results == [heathrow])
    }

    @Test func filtersByCity() throws {
        let heathrow = try airport("LHR")
        let results = AirportFiltering.filter(AirportCatalog.all, query: "  London ")
        #expect(results == [heathrow])
    }

    @Test func filtersByAirportName() throws {
        let changi = try airport("SIN")
        let results = AirportFiltering.filter(AirportCatalog.all, query: "changi")
        #expect(results == [changi])
    }

    @Test func unmatchedQueryReturnsAnEmptyList() {
        #expect(AirportFiltering.filter(AirportCatalog.all, query: "zzz").isEmpty)
    }

    private func airport(_ code: String) throws -> Airport {
        try #require(AirportCatalog.all.first { $0.iataCode == code })
    }
}
