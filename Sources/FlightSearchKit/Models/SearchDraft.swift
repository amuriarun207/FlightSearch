import Foundation

enum TripType: String, CaseIterable, Identifiable, Sendable {
    case oneWay
    case roundTrip = "return"
    case multiCity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneWay:
            "One way"
        case .roundTrip:
            "Return"
        case .multiCity:
            "Multi-city"
        }
    }

    var detail: String {
        switch self {
        case .oneWay:
            "One-way journey"
        case .roundTrip:
            "Return journey"
        case .multiCity:
            "Multi-city journey"
        }
    }

    static func stored(_ rawValue: String?) -> TripType {
        guard let rawValue, let match = TripType(rawValue: rawValue) else {
            return .oneWay
        }
        return match
    }
}

struct SearchDraft: Equatable, Sendable {
    var tripType: TripType
    var originCode: String?
    var destinationCode: String?

    static let empty = SearchDraft(tripType: .oneWay, originCode: nil, destinationCode: nil)
}

enum AirportEndpoint: String, Identifiable, Sendable {
    case origin
    case destination

    var id: String { rawValue }

    var fieldTitle: String {
        switch self {
        case .origin:
            "From"
        case .destination:
            "To"
        }
    }

    var navigationTitle: String {
        switch self {
        case .origin:
            "Departure airport"
        case .destination:
            "Arrival airport"
        }
    }
}
