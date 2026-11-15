import SwiftUI

struct AirportSelectionSheet: View {
    let endpoint: AirportEndpoint
    let airports: [Airport]
    let onSelect: (Airport) -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @FocusState private var isQueryFocused: Bool

    private var colors: FlightSearchColors { FlightSearchColors(scheme: colorScheme) }

    private var results: [Airport] {
        AirportFiltering.filter(airports, query: query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchField
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                if results.isEmpty {
                    ContentUnavailableView {
                        Label("No airports found", systemImage: "airplane")
                    } description: {
                        Text("Try a different city, airport name, or IATA code.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { airport in
                        airportRow(airport)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(colors.canvas)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .flightSearchScrollsPastKeyboard()
                }
            }
            .background(colors.canvas)
            .navigationTitle(endpoint.navigationTitle)
            .flightSearchInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .accessibilityLabel("Cancel airport selection")
                }
            }
            .flightSearchKeyboardDismiss {
                isQueryFocused = false
            }
        }
        .flightSearchDragIndicator()
        .onAppear {
            isQueryFocused = true
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(colors.secondaryText)
                .accessibilityHidden(true)
            TextField("City, airport, or code", text: $query)
                .focused($isQueryFocused)
                .flightSearchDisablesAutocapitalization()
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
                .accessibilityLabel("Search airports")
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(colors.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(colors.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func airportRow(_ airport: Airport) -> some View {
        Button {
            onSelect(airport)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(airport.city)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(colors.primaryText)
                    Text(airport.name)
                        .font(.subheadline)
                        .foregroundStyle(colors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Text(airport.iataCode)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colors.accent.opacity(0.12), in: Capsule())
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(airport.city), \(airport.name), \(airport.iataCode)")
        .accessibilityHint("Selects this airport")
    }
}

#Preview("Airports") {
    AirportSelectionSheet(
        endpoint: .origin,
        airports: AirportCatalog.all,
        onSelect: { _ in },
        onCancel: {}
    )
}

#Preview("No matches") {
    AirportSelectionSheet(
        endpoint: .destination,
        airports: [],
        onSelect: { _ in },
        onCancel: {}
    )
}
