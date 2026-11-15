import Foundation

struct Airport: Identifiable, Hashable, Sendable {
    let iataCode: String
    let name: String
    let city: String

    var id: String { iataCode }
}
