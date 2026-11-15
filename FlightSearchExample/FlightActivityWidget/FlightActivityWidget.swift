import ActivityKit
import FlightActivityAttributes
import SwiftUI
import WidgetKit

@main
struct FlightActivityBundle: WidgetBundle {
    var body: some Widget {
        FlightActivityWidget()
    }
}

struct FlightActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlightActivityAttributes.self) { context in
            FlightLockScreenView(
                attributes: context.attributes,
                state: context.state,
                isStale: context.isStale
            )
            .widgetURL(FlightActivityLink.status)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    FlightExpandedLeadingView(attributes: context.attributes)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    FlightExpandedTrailingView(attributes: context.attributes)
                }
                DynamicIslandExpandedRegion(.center) {
                    FlightExpandedCenterView(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    FlightDetachedStatusView(
                        attributes: context.attributes,
                        state: context.state,
                        isStale: context.isStale
                    )
                }
            } compactLeading: {
                FlightAttachedLeadingView(attributes: context.attributes)
            } compactTrailing: {
                FlightAttachedTrailingView(state: context.state)
            } minimal: {
                FlightMinimalView(attributes: context.attributes, state: context.state)
            }
            .keylineTint(FlightActivityPalette.accent)
            .widgetURL(FlightActivityLink.status)
        }
    }
}

private enum FlightActivityLink {
    static let status = URL(string: "flightsearch://status")
}

#Preview("Lock Screen", as: .content, using: FlightActivityAttributes.simulatorSample) {
    FlightActivityWidget()
} contentStates: {
    FlightPhase.boarding.sampleContent
    FlightPhase.delayed.sampleContent
    FlightPhase.inFlight.sampleContent
}

#Preview("Attached", as: .dynamicIsland(.compact), using: FlightActivityAttributes.simulatorSample) {
    FlightActivityWidget()
} contentStates: {
    FlightPhase.boarding.sampleContent
    FlightPhase.delayed.sampleContent
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: FlightActivityAttributes.simulatorSample) {
    FlightActivityWidget()
} contentStates: {
    FlightPhase.inFlight.sampleContent
    FlightPhase.cancelled.sampleContent
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: FlightActivityAttributes.simulatorSample) {
    FlightActivityWidget()
} contentStates: {
    FlightPhase.delayed.sampleContent
    FlightPhase.landed.sampleContent
}
