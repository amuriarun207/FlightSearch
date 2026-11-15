import FlightActivityAttributes
import SwiftUI

struct FlightTrackingControls: View {
    let originCode: String
    let originCity: String
    let destinationCode: String
    let destinationCity: String
    let colors: FlightSearchColors
    var client: LiveFlightActivityClient

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flight status")
                .font(.headline)
                .foregroundStyle(colors.primaryText)
            Text("This stays on the Lock Screen and Dynamic Island. The simulator can update it from the .apns files before a server exists.")
                .font(.footnote)
                .foregroundStyle(colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: track) {
                Text(client.isTracking ? "Restart tracking" : "Track on Lock Screen")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }
            .buttonStyle(.plain)
            .background(colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityHint("Starts a flight status Live Activity")

            if client.isTracking {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(FlightPhase.allCases) { phase in
                        Button {
                            client.apply(phase)
                        } label: {
                            Text(phase.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(client.phase == phase ? Color.white : colors.primaryText)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 40)
                                .background(
                                    client.phase == phase ? colors.accent : colors.field,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Set flight status to \(phase.title)")
                    }
                }
                Button("Remove from Lock Screen", action: client.remove)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(colors.accent)
                    .frame(minHeight: 44)
            }

            if let statusMessage = client.statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if client.hasPushToken {
                Text("Activity push token captured for the server later.")
                    .font(.footnote)
                    .foregroundStyle(colors.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func track() {
        client.track(
            originCode: originCode,
            originCity: originCity,
            destinationCode: destinationCode,
            destinationCity: destinationCity
        )
    }
}
