import FlightActivityAttributes
import SwiftUI
import WidgetKit

struct FlightLockScreenView: View {
    let attributes: FlightActivityAttributes
    let state: FlightActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(attributes.flightNumber)
                    .font(.headline.weight(.bold))
                Spacer(minLength: 8)
                FlightPhaseBadge(state: state)
            }
            HStack(alignment: .center, spacing: 8) {
                FlightAirportColumn(
                    code: attributes.originCode,
                    city: attributes.originCity,
                    time: attributes.scheduledDeparture,
                    alignment: .leading
                )
                FlightRouteMark(progress: state.visibleProgress)
                FlightAirportColumn(
                    code: attributes.destinationCode,
                    city: attributes.destinationCity,
                    time: attributes.scheduledArrival,
                    alignment: .trailing
                )
            }
            FlightProgressBar(progress: state.visibleProgress)
            FlightStatusDetail(attributes: attributes, state: state, isStale: isStale)
        }
        .padding(16)
        .foregroundStyle(.white)
        .activityBackgroundTint(FlightActivityPalette.background)
        .activitySystemActionForegroundColor(.white)
    }
}

/// Compact Dynamic Island, attached to the leading side of the camera.
struct FlightAttachedLeadingView: View {
    let attributes: FlightActivityAttributes

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.caption2.weight(.bold))
            Text(attributes.flightNumber)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(FlightActivityPalette.accent)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flight \(attributes.flightNumber)")
    }
}

/// Compact Dynamic Island, attached to the trailing side of the camera.
struct FlightAttachedTrailingView: View {
    let state: FlightActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.phase.systemImage)
                .font(.caption2.weight(.bold))
            Text(shortValue)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(state.delayMinutes > 0 ? FlightActivityPalette.warning : .white)
        .accessibilityLabel(state.statusLine)
    }

    private var shortValue: String {
        if state.delayMinutes > 0 {
            return "\(state.delayMinutes)m"
        }
        if !state.gate.isEmpty {
            return state.gate
        }
        return state.phase.title
    }
}

/// Smallest Dynamic Island presentation, used when another activity is also active.
struct FlightMinimalView: View {
    let attributes: FlightActivityAttributes
    let state: FlightActivityAttributes.ContentState

    var body: some View {
        Image(systemName: state.phase.systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(state.delayMinutes > 0 ? FlightActivityPalette.warning : FlightActivityPalette.accent)
            .accessibilityLabel("\(attributes.flightNumber), \(state.statusLine)")
    }
}

struct FlightExpandedLeadingView: View {
    let attributes: FlightActivityAttributes

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(attributes.originCode)
                .font(.title3.weight(.bold))
            Text(attributes.originCity)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
            Text(attributes.scheduledDeparture, format: .dateTime.hour().minute())
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}

struct FlightExpandedTrailingView: View {
    let attributes: FlightActivityAttributes

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(attributes.destinationCode)
                .font(.title3.weight(.bold))
            Text(attributes.destinationCity)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
            Text(attributes.scheduledArrival, format: .dateTime.hour().minute())
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}

/// Sits in the camera cutout. Keep this decorative; the gate is repeated below.
struct FlightExpandedCenterView: View {
    let state: FlightActivityAttributes.ContentState

    var body: some View {
        Image(systemName: state.phase.systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(FlightActivityPalette.accent)
            .accessibilityHidden(true)
    }
}

/// Expanded content that sits below the island, detached from the camera.
struct FlightDetachedStatusView: View {
    let attributes: FlightActivityAttributes
    let state: FlightActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(state.statusLine, systemImage: state.phase.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(state.delayMinutes > 0 ? FlightActivityPalette.warning : .white)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(attributes.flightNumber)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FlightActivityPalette.accent)
            }
            FlightProgressBar(progress: state.visibleProgress)
            FlightStatusDetail(attributes: attributes, state: state, isStale: isStale)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

private struct FlightAirportColumn: View {
    let code: String
    let city: String
    let time: Date
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(code)
                .font(.title2.weight(.bold))
                .minimumScaleFactor(0.8)
            Text(city)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
            Text(time, format: .dateTime.hour().minute())
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
        .accessibilityElement(children: .combine)
    }
}

private struct FlightRouteMark: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.caption.weight(.bold))
                .foregroundStyle(FlightActivityPalette.accent)
            FlightProgressBar(progress: progress)
                .frame(width: 44)
        }
        .accessibilityHidden(true)
    }
}

private struct FlightPhaseBadge: View {
    let state: FlightActivityAttributes.ContentState

    var body: some View {
        Label(state.statusLine, systemImage: state.phase.systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(state.delayMinutes > 0 ? FlightActivityPalette.warning : FlightActivityPalette.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct FlightStatusDetail: View {
    let attributes: FlightActivityAttributes
    let state: FlightActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(gateLine)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
            if isStale {
                Text("Status may be outdated")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FlightActivityPalette.warning)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var gateLine: String {
        let gate = state.gate.isEmpty ? "Gate pending" : "Gate \(state.gate)"
        let terminal = state.terminal.isEmpty ? "" : " · Terminal \(state.terminal)"
        return "\(attributes.originCode) to \(attributes.destinationCode) · \(gate)\(terminal)"
    }
}

struct FlightProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.white.opacity(0.18))
            Capsule()
                .fill(FlightActivityPalette.accent)
                .frame(width: max(progress > 0 ? 6 : 0, proxy.size.width * progress))
        }
        .frame(height: 6)
        .accessibilityLabel("Flight progress")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }
}

enum FlightActivityPalette {
    static let accent = Color(red: 0.784, green: 0.063, blue: 0.180)
    static let warning = Color(red: 0.96, green: 0.72, blue: 0.28)
    static let background = Color(red: 0.10, green: 0.06, blue: 0.07)
}

extension FlightPhase {
    var systemImage: String {
        switch self {
        case .scheduled:
            "clock"
        case .boarding:
            "figure.walk"
        case .departed:
            "airplane.departure"
        case .inFlight:
            "airplane"
        case .landed:
            "airplane.arrival"
        case .delayed:
            "exclamationmark.triangle"
        case .cancelled:
            "xmark.circle"
        }
    }
}

#Preview("Lock Screen") {
    FlightLockScreenView(
        attributes: .simulatorSample,
        state: FlightPhase.boarding.sampleContent,
        isStale: false
    )
}

#Preview("Attached compact") {
    HStack {
        FlightAttachedLeadingView(attributes: .simulatorSample)
        Spacer()
        FlightAttachedTrailingView(state: FlightPhase.boarding.sampleContent)
    }
    .padding(.horizontal, 12)
    .frame(width: 220, height: 36)
    .background(.black, in: Capsule())
}

#Preview("Minimal") {
    FlightMinimalView(attributes: .simulatorSample, state: FlightPhase.inFlight.sampleContent)
        .frame(width: 36, height: 36)
        .background(.black, in: Circle())
}

#Preview("Expanded detached") {
    VStack(spacing: 8) {
        HStack {
            FlightExpandedLeadingView(attributes: .simulatorSample)
            Spacer()
            FlightExpandedCenterView(state: FlightPhase.delayed.sampleContent)
            Spacer()
            FlightExpandedTrailingView(attributes: .simulatorSample)
        }
        FlightDetachedStatusView(
            attributes: .simulatorSample,
            state: FlightPhase.delayed.sampleContent,
            isStale: true
        )
    }
    .padding()
    .background(FlightActivityPalette.background)
}
