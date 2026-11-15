import SwiftUI

/// Flight search home screen.
/// Restores the last trip type, departure airport, and arrival airport.
public struct FlightSearchView: View {
    @State private var model: FlightSearchModel
    @State private var liveActivity = LiveFlightActivityClient()
    @Environment(\.colorScheme) private var colorScheme

    public init() {
        self.init(store: CoreDataSearchDraftStore())
    }

    init(store: any SearchDraftStoring) {
        _model = State(initialValue: FlightSearchModel(store: store))
    }

    private var colors: FlightSearchColors { FlightSearchColors(scheme: colorScheme) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                tripTypePicker
                routeCard
                if !model.issues.isEmpty {
                    validationList
                }
                searchButton
                if let confirmation = model.confirmation {
                    confirmationCard(confirmation)
                    FlightTrackingControls(
                        originCode: confirmation.origin.iataCode,
                        originCity: confirmation.origin.city,
                        destinationCode: confirmation.destination.iataCode,
                        destinationCity: confirmation.destination.city,
                        colors: colors,
                        client: liveActivity
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(colors.canvas.ignoresSafeArea())
        .flightSearchScrollsPastKeyboard()
        .sheet(
            item: Binding(
                get: { model.activeEndpoint },
                set: { endpoint in
                    if let endpoint {
                        model.beginSelection(endpoint)
                    } else {
                        model.cancelSelection()
                    }
                }
            )
        ) { endpoint in
            AirportSelectionSheet(
                endpoint: endpoint,
                airports: model.airports,
                onSelect: { airport in
                    model.select(airport, for: endpoint)
                },
                onCancel: {
                    model.cancelSelection()
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(colors.accent)
                .frame(width: 36, height: 4)
                .accessibilityHidden(true)
            Text("Book a flight")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(colors.primaryText)
                .accessibilityAddTraits(.isHeader)
            Text("Choose a departure and arrival airport.")
                .font(.subheadline)
                .foregroundStyle(colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tripTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(
                "Trip type",
                selection: Binding(
                    get: { model.tripType },
                    set: { model.updateTripType($0) }
                )
            ) {
                ForEach(TripType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .tint(colors.accent)
            Text(model.tripType.detail)
                .font(.footnote)
                .foregroundStyle(colors.secondaryText)
        }
    }

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Route")
                .font(.headline)
                .foregroundStyle(colors.primaryText)
            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 10) {
                    AirportField(
                        title: AirportEndpoint.origin.fieldTitle,
                        airport: model.origin,
                        colors: colors
                    ) {
                        model.beginSelection(.origin)
                    }
                    AirportField(
                        title: AirportEndpoint.destination.fieldTitle,
                        airport: model.destination,
                        colors: colors
                    ) {
                        model.beginSelection(.destination)
                    }
                }
                swapButton
            }
        }
        .padding(16)
        .background(colors.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 16, y: 6)
    }

    private var swapButton: some View {
        Button(action: model.swapAirports) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.body.weight(.semibold))
                .foregroundStyle(colors.accent)
                .frame(width: 44, height: 44)
                .background(colors.card, in: Circle())
                .overlay {
                    Circle().strokeBorder(colors.accent.opacity(0.35), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(model.origin == nil && model.destination == nil)
        .accessibilityLabel("Swap departure and arrival airports")
    }

    private var validationList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(model.issues) { issue in
                Label(issue.message, systemImage: "exclamationmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(colors.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var searchButton: some View {
        Button(action: model.search) {
            Text("Search flights")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
        }
        .buttonStyle(.plain)
        .background(colors.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHint("Confirms the selected route")
    }

    private func confirmationCard(_ confirmation: ConfirmedRoute) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(colors.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Route confirmed")
                    .font(.headline)
                    .foregroundStyle(colors.primaryText)
                Text(confirmation.summary)
                    .font(.subheadline)
                    .foregroundStyle(colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(confirmation.tripType.title)
                    .font(.footnote)
                    .foregroundStyle(colors.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Empty") {
    FlightSearchView(store: CoreDataSearchDraftStore(location: .inMemory))
}

#Preview("Restored") {
    let store = CoreDataSearchDraftStore(location: .inMemory)
    try? store.save(
        SearchDraft(tripType: .roundTrip, originCode: "DXB", destinationCode: "LHR")
    )
    return FlightSearchView(store: store)
}

#Preview("Dark") {
    FlightSearchView(store: CoreDataSearchDraftStore(location: .inMemory))
        .preferredColorScheme(.dark)
}
