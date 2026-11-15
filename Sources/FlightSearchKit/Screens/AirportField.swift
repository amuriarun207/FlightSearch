import SwiftUI

struct AirportField: View {
    let title: String
    let airport: Airport?
    let colors: FlightSearchColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(colors.accent)
                        .tracking(0.6)
                    if let airport {
                        Text(airport.city)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(colors.primaryText)
                        Text("\(airport.iataCode) · \(airport.name)")
                            .font(.subheadline)
                            .foregroundStyle(colors.secondaryText)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Select airport")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(colors.secondaryText)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(colors.secondaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(colors.field, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Shows the airport list")
    }

    private var accessibilityLabel: String {
        guard let airport else {
            return "\(title), not selected"
        }
        return "\(title), \(airport.city), \(airport.name), \(airport.iataCode)"
    }
}
