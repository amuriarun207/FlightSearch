import Testing
@testable import FlightSearchKit

@MainActor
struct FlightSearchModelTests {
    @Test func selectionPersistsAcrossANewModel() throws {
        let store = CoreDataSearchDraftStore(location: .inMemory)
        let first = FlightSearchModel(store: store)
        first.updateTripType(.multiCity)
        first.select(try airport("DXB"), for: .origin)
        first.select(try airport("LHR"), for: .destination)

        let restored = FlightSearchModel(store: store)
        let dubai = try airport("DXB")
        let london = try airport("LHR")
        #expect(restored.tripType == .multiCity)
        #expect(restored.origin == dubai)
        #expect(restored.destination == london)
    }

    @Test func cancellingSelectionKeepsTheCurrentAirports() throws {
        let model = FlightSearchModel(store: CoreDataSearchDraftStore(location: .inMemory))
        model.select(try airport("DXB"), for: .origin)
        model.beginSelection(.destination)
        model.cancelSelection()

        let dubai = try airport("DXB")
        #expect(model.origin == dubai)
        #expect(model.destination == nil)
        #expect(model.activeEndpoint == nil)
    }

    @Test func selectingAnAirportClosesTheSheetAndSavesIt() throws {
        let store = CoreDataSearchDraftStore(location: .inMemory)
        let model = FlightSearchModel(store: store)
        model.beginSelection(.origin)
        let doha = try airport("DOH")
        model.select(doha, for: .origin)

        #expect(model.origin == doha)
        #expect(model.activeEndpoint == nil)
        #expect(try store.load().originCode == "DOH")
    }

    @Test func swapExchangesTheAirportsAndPersistsThem() throws {
        let store = CoreDataSearchDraftStore(location: .inMemory)
        let model = FlightSearchModel(store: store)
        model.select(try airport("DXB"), for: .origin)
        model.select(try airport("SIN"), for: .destination)
        model.swapAirports()

        let singapore = try airport("SIN")
        let dubai = try airport("DXB")
        #expect(model.origin == singapore)
        #expect(model.destination == dubai)
        let draft = try store.load()
        #expect(draft.originCode == "SIN")
        #expect(draft.destinationCode == "DXB")
    }

    @Test func swapWithOnlyADepartureMovesItToArrival() throws {
        let model = FlightSearchModel(store: CoreDataSearchDraftStore(location: .inMemory))
        model.select(try airport("FRA"), for: .origin)
        model.swapAirports()
        let frankfurt = try airport("FRA")
        #expect(model.origin == nil)
        #expect(model.destination == frankfurt)
    }

    @Test func searchRequiresTwoDifferentAirports() throws {
        let model = FlightSearchModel(store: CoreDataSearchDraftStore(location: .inMemory))
        model.search()
        #expect(model.issues == [.missingOrigin, .missingDestination])
        #expect(model.confirmation == nil)

        model.select(try airport("LAX"), for: .origin)
        model.select(try airport("LAX"), for: .destination)
        model.search()
        #expect(model.issues == [.sameAirport])
        #expect(model.confirmation == nil)
    }

    @Test func searchConfirmsAValidRouteWithoutChangingTheSavedDraft() throws {
        let store = CoreDataSearchDraftStore(location: .inMemory)
        let model = FlightSearchModel(store: store)
        model.updateTripType(.roundTrip)
        model.select(try airport("BOM"), for: .origin)
        model.select(try airport("DEL"), for: .destination)
        model.search()

        let confirmation = try #require(model.confirmation)
        #expect(confirmation.summary == "Mumbai (BOM) to Delhi (DEL)")
        #expect(confirmation.tripType == .roundTrip)
        #expect(model.issues.isEmpty)
        #expect(try store.load() == SearchDraft(tripType: .roundTrip, originCode: "BOM", destinationCode: "DEL"))
    }

    @Test func changingTheRouteClearsAPreviousConfirmation() throws {
        let model = FlightSearchModel(store: CoreDataSearchDraftStore(location: .inMemory))
        model.select(try airport("DXB"), for: .origin)
        model.select(try airport("LHR"), for: .destination)
        model.search()
        #expect(model.confirmation != nil)

        model.updateTripType(.multiCity)
        #expect(model.confirmation == nil)
        #expect(model.issues.isEmpty)
    }

    private func airport(_ code: String) throws -> Airport {
        try #require(AirportCatalog.all.first { $0.iataCode == code })
    }
}
