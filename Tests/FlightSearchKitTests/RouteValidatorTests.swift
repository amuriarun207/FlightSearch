import Testing
@testable import FlightSearchKit

struct RouteValidatorTests {
    private let dubai = Airport(iataCode: "DXB", name: "Dubai International Airport", city: "Dubai")
    private let london = Airport(iataCode: "LHR", name: "Heathrow Airport", city: "London")

    @Test func missingBothAirportsReportsBothIssues() {
        #expect(RouteValidator.issues(origin: nil, destination: nil) == [.missingOrigin, .missingDestination])
    }

    @Test func missingDestinationIsReported() {
        #expect(RouteValidator.issues(origin: dubai, destination: nil) == [.missingDestination])
    }

    @Test func missingOriginIsReported() {
        #expect(RouteValidator.issues(origin: nil, destination: london) == [.missingOrigin])
    }

    @Test func sameAirportIsRejectedEvenWhenTheNamesDiffer() {
        let otherDubai = Airport(iataCode: "dxb", name: "Another name", city: "Dubai")
        #expect(RouteValidator.issues(origin: dubai, destination: otherDubai) == [.sameAirport])
    }

    @Test func aDistinctRouteHasNoIssues() {
        #expect(RouteValidator.issues(origin: dubai, destination: london).isEmpty)
    }

    @Test func issueMessagesAreSpecific() {
        #expect(RouteIssue.missingOrigin.message == "Choose a departure airport.")
        #expect(RouteIssue.missingDestination.message == "Choose an arrival airport.")
        #expect(RouteIssue.sameAirport.message == "Departure and arrival must be different airports.")
    }
}
