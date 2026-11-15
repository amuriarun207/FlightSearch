import Foundation
import Observation

@MainActor
@Observable
final class FlightSearchModel {
    private(set) var tripType: TripType
    private(set) var origin: Airport?
    private(set) var destination: Airport?
    private(set) var activeEndpoint: AirportEndpoint?
    private(set) var issues: [RouteIssue] = []
    private(set) var confirmation: ConfirmedRoute?

    @ObservationIgnored
    let airports: [Airport]

    @ObservationIgnored
    private let store: any SearchDraftStoring

    init(store: any SearchDraftStoring, airports: [Airport] = AirportCatalog.all) {
        self.store = store
        self.airports = airports
        let draft = (try? store.load()) ?? .empty
        tripType = draft.tripType
        origin = AirportCatalog.airport(code: draft.originCode, in: airports)
        destination = AirportCatalog.airport(code: draft.destinationCode, in: airports)
    }

    func updateTripType(_ tripType: TripType) {
        guard self.tripType != tripType else { return }
        self.tripType = tripType
        invalidateSearchFeedback()
        persist()
    }

    func beginSelection(_ endpoint: AirportEndpoint) {
        activeEndpoint = endpoint
    }

    func select(_ airport: Airport, for endpoint: AirportEndpoint) {
        switch endpoint {
        case .origin:
            origin = airport
        case .destination:
            destination = airport
        }
        activeEndpoint = nil
        invalidateSearchFeedback()
        persist()
    }

    func cancelSelection() {
        activeEndpoint = nil
    }

    func swapAirports() {
        guard origin != nil || destination != nil else { return }
        let previousOrigin = origin
        origin = destination
        destination = previousOrigin
        invalidateSearchFeedback()
        persist()
    }

    func search() {
        let found = RouteValidator.issues(origin: origin, destination: destination)
        issues = found
        guard found.isEmpty, let origin, let destination else {
            confirmation = nil
            return
        }
        confirmation = ConfirmedRoute(tripType: tripType, origin: origin, destination: destination)
    }

    private func invalidateSearchFeedback() {
        issues = []
        confirmation = nil
    }

    private func persist() {
        try? store.save(
            SearchDraft(
                tripType: tripType,
                originCode: origin?.iataCode,
                destinationCode: destination?.iataCode
            )
        )
    }
}
