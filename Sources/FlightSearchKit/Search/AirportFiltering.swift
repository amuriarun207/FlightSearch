import Foundation

enum AirportFiltering {
    static func filter(_ airports: [Airport], query: String) -> [Airport] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return airports }

        return airports.filter { airport in
            airport.name.localizedStandardContains(needle)
                || airport.city.localizedStandardContains(needle)
                || airport.iataCode.localizedStandardContains(needle)
        }
    }
}
