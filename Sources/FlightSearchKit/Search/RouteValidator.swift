import Foundation

enum RouteIssue: Hashable, Identifiable, Sendable {
    case missingOrigin
    case missingDestination
    case sameAirport

    var id: Self { self }

    var message: String {
        switch self {
        case .missingOrigin:
            "Choose a departure airport."
        case .missingDestination:
            "Choose an arrival airport."
        case .sameAirport:
            "Departure and arrival must be different airports."
        }
    }
}

enum RouteValidator {
    static func issues(origin: Airport?, destination: Airport?) -> [RouteIssue] {
        var issues: [RouteIssue] = []
        if origin == nil {
            issues.append(.missingOrigin)
        }
        if destination == nil {
            issues.append(.missingDestination)
        }
        if let origin, let destination, origin.iataCode.caseInsensitiveCompare(destination.iataCode) == .orderedSame {
            issues.append(.sameAirport)
        }
        return issues
    }
}

struct ConfirmedRoute: Equatable, Sendable {
    let tripType: TripType
    let origin: Airport
    let destination: Airport

    var summary: String {
        "\(origin.city) (\(origin.iataCode)) to \(destination.city) (\(destination.iataCode))"
    }
}
