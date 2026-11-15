import Foundation

enum AirportCatalog {
    static let all: [Airport] = [
        Airport(iataCode: "DXB", name: "Dubai International Airport", city: "Dubai"),
        Airport(iataCode: "LHR", name: "Heathrow Airport", city: "London"),
        Airport(iataCode: "JFK", name: "John F. Kennedy International Airport", city: "New York"),
        Airport(iataCode: "BOM", name: "Chhatrapati Shivaji Maharaj International Airport", city: "Mumbai"),
        Airport(iataCode: "SIN", name: "Changi Airport", city: "Singapore"),
        Airport(iataCode: "DOH", name: "Hamad International Airport", city: "Doha"),
        Airport(iataCode: "SYD", name: "Kingsford Smith Airport", city: "Sydney"),
        Airport(iataCode: "FRA", name: "Frankfurt Airport", city: "Frankfurt"),
        Airport(iataCode: "LAX", name: "Los Angeles International Airport", city: "Los Angeles"),
        Airport(iataCode: "DEL", name: "Indira Gandhi International Airport", city: "Delhi"),
    ]

    static func airport(code: String?, in airports: [Airport] = all) -> Airport? {
        guard let code else { return nil }
        let needle = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return nil }
        return airports.first { airport in
            airport.iataCode.caseInsensitiveCompare(needle) == .orderedSame
        }
    }
}
