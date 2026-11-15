import Foundation
#if os(iOS)
import ActivityKit
#endif

public enum FlightPhase: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case scheduled
    case boarding
    case departed
    case inFlight
    case landed
    case delayed
    case cancelled

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .scheduled:
            "Scheduled"
        case .boarding:
            "Boarding"
        case .departed:
            "Departed"
        case .inFlight:
            "In flight"
        case .landed:
            "Landed"
        case .delayed:
            "Delayed"
        case .cancelled:
            "Cancelled"
        }
    }

    public var showsAsEnded: Bool {
        self == .landed || self == .cancelled
    }

    public var sampleContent: FlightActivityAttributes.ContentState {
        switch self {
        case .scheduled:
            FlightActivityAttributes.ContentState(phase: self, gate: "A12", terminal: "3", delayMinutes: 0, progress: 0)
        case .boarding:
            FlightActivityAttributes.ContentState(phase: self, gate: "A12", terminal: "3", delayMinutes: 0, progress: 0.25)
        case .departed:
            FlightActivityAttributes.ContentState(phase: self, gate: "A12", terminal: "3", delayMinutes: 0, progress: 0.5)
        case .inFlight:
            FlightActivityAttributes.ContentState(phase: self, gate: "A12", terminal: "3", delayMinutes: 0, progress: 0.75)
        case .delayed:
            FlightActivityAttributes.ContentState(phase: self, gate: "B7", terminal: "1", delayMinutes: 40, progress: 0.25)
        case .landed:
            FlightActivityAttributes.ContentState(phase: self, gate: "C18", terminal: "5", delayMinutes: 0, progress: 1)
        case .cancelled:
            FlightActivityAttributes.ContentState(phase: self, gate: "A12", terminal: "3", delayMinutes: 0, progress: 0)
        }
    }
}

public struct FlightActivityAttributes: Codable, Hashable, Sendable {
    public var flightNumber: String
    public var originCode: String
    public var originCity: String
    public var destinationCode: String
    public var destinationCity: String
    public var scheduledDeparture: Date
    public var scheduledArrival: Date

    public struct ContentState: Codable, Hashable, Sendable {
        public var phase: FlightPhase
        public var gate: String
        public var terminal: String
        public var delayMinutes: Int
        public var progress: Double

        public init(
            phase: FlightPhase,
            gate: String,
            terminal: String,
            delayMinutes: Int,
            progress: Double
        ) {
            self.phase = phase
            self.gate = gate
            self.terminal = terminal
            self.delayMinutes = delayMinutes
            self.progress = min(max(progress, 0), 1)
        }

        public var visibleProgress: Double {
            min(max(progress, 0), 1)
        }

        public var statusLine: String {
            if delayMinutes > 0 {
                return "Delayed \(delayMinutes) min"
            }
            return phase.title
        }
    }

    public init(
        flightNumber: String,
        originCode: String,
        originCity: String,
        destinationCode: String,
        destinationCity: String,
        scheduledDeparture: Date,
        scheduledArrival: Date
    ) {
        self.flightNumber = flightNumber
        self.originCode = originCode
        self.originCity = originCity
        self.destinationCode = destinationCode
        self.destinationCity = destinationCity
        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
    }

    public static let simulatorSample = FlightActivityAttributes(
        flightNumber: "FS412",
        originCode: "DXB",
        originCity: "Dubai",
        destinationCode: "LHR",
        destinationCity: "London",
        scheduledDeparture: Date(timeIntervalSince1970: 1_795_000_000),
        scheduledArrival: Date(timeIntervalSince1970: 1_795_021_600)
    )

    public static func make(
        originCode: String,
        originCity: String,
        destinationCode: String,
        destinationCity: String,
        departure: Date = .now
    ) -> FlightActivityAttributes {
        FlightActivityAttributes(
            flightNumber: flightNumber(originCode: originCode, destinationCode: destinationCode),
            originCode: originCode,
            originCity: originCity,
            destinationCode: destinationCode,
            destinationCity: destinationCity,
            scheduledDeparture: departure.addingTimeInterval(2 * 60 * 60),
            scheduledArrival: departure.addingTimeInterval(8 * 60 * 60)
        )
    }

    public static func flightNumber(originCode: String, destinationCode: String) -> String {
        let total = (originCode + destinationCode).unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
        return "FS\(100 + total % 800)"
    }
}

#if os(iOS)
extension FlightActivityAttributes: ActivityAttributes {}
#endif

public struct FlightActivityPush: Equatable, Sendable {
    public var event: String
    public var contentState: FlightActivityAttributes.ContentState
    public var attributes: FlightActivityAttributes?
    public var timestamp: TimeInterval

    public init(
        event: String,
        contentState: FlightActivityAttributes.ContentState,
        attributes: FlightActivityAttributes?,
        timestamp: TimeInterval
    ) {
        self.event = event
        self.contentState = contentState
        self.attributes = attributes
        self.timestamp = timestamp
    }
}

public enum FlightActivityPushDecoding {
    public static func decode(_ data: Data) throws -> FlightActivityPush {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let envelope = try decoder.decode(Envelope.self, from: data)
        return FlightActivityPush(
            event: envelope.aps.event,
            contentState: envelope.aps.contentState,
            attributes: envelope.aps.attributes,
            timestamp: envelope.aps.timestamp
        )
    }
}

private struct Envelope: Decodable {
    let aps: APS

    struct APS: Decodable {
        let timestamp: TimeInterval
        let event: String
        let contentState: FlightActivityAttributes.ContentState
        let attributes: FlightActivityAttributes?

        enum CodingKeys: String, CodingKey {
            case timestamp
            case event
            case contentState = "content-state"
            case attributes
        }
    }
}
