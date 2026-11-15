import FlightActivityAttributes
import Foundation
import Observation
#if os(iOS)
import ActivityKit
#endif

@MainActor
@Observable
final class LiveFlightActivityClient {
    private(set) var isTracking = false
    private(set) var phase: FlightPhase?
    private(set) var statusMessage: String?
    private(set) var hasPushToken = false

    #if os(iOS)
    private var activity: Activity<FlightActivityAttributes>?
    private var tokenTask: Task<Void, Never>?
    private var pushToStartTask: Task<Void, Never>?
    #endif

    init() {
        #if os(iOS)
        observePushToStart()
        #endif
    }

    func track(originCode: String, originCity: String, destinationCode: String, destinationCity: String) {
        let attributes = FlightActivityAttributes.make(
            originCode: originCode,
            originCity: originCity,
            destinationCode: destinationCode,
            destinationCity: destinationCity
        )
        let state = FlightPhase.scheduled.sampleContent
        #if os(iOS)
        Task { await begin(attributes, state: state) }
        #else
        isTracking = true
        phase = state.phase
        statusMessage = "Live Activities run in the iOS app."
        #endif
    }

    func apply(_ phase: FlightPhase) {
        #if os(iOS)
        Task { await publish(phase.sampleContent) }
        #else
        self.phase = phase
        isTracking = !phase.showsAsEnded
        #endif
    }

    func remove() {
        #if os(iOS)
        Task { await clear() }
        #else
        isTracking = false
        phase = nil
        statusMessage = "Removed from the Lock Screen."
        #endif
    }

    #if os(iOS)
    private func begin(
        _ attributes: FlightActivityAttributes,
        state: FlightActivityAttributes.ContentState
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "Turn on Live Activities for FlightSearchExample in Settings."
            isTracking = false
            return
        }

        for existing in Activity<FlightActivityAttributes>.activities {
            await LiveActivityBridge.end(existing, content: nil, dismissalPolicy: .immediate)
        }

        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(20 * 60)
        )
        let started: StartedActivity
        do {
            started = try await start(attributes, content: content)
        } catch {
            isTracking = false
            phase = nil
            hasPushToken = false
            statusMessage = Self.message(for: error)
            return
        }

        activity = started.activity
        isTracking = true
        phase = state.phase
        hasPushToken = false
        if started.requestsPushToken {
            statusMessage = "Showing on the Lock Screen. Drop the next .apns file to change it."
            observePushToken(for: started.activity)
        } else {
            statusMessage = "Showing on the Lock Screen. Phase buttons and .apns files can update it. The push token appears after you add the Push Notifications capability."
        }
    }

    private struct StartedActivity {
        let activity: Activity<FlightActivityAttributes>
        let requestsPushToken: Bool
    }

    private func start(
        _ attributes: FlightActivityAttributes,
        content: ActivityContent<FlightActivityAttributes.ContentState>
    ) async throws -> StartedActivity {
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            return StartedActivity(activity: activity, requestsPushToken: true)
        } catch {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            return StartedActivity(activity: activity, requestsPushToken: false)
        }
    }

    private static func message(for error: Error) -> String {
        if let authorization = error as? ActivityAuthorizationError {
            switch authorization {
            case .denied:
                return "Turn on Live Activities for FlightSearchExample in Settings."
            case .visibility:
                return "Keep FlightSearchExample open, then track the flight again."
            case .unsupported, .unsupportedTarget:
                return "This simulator cannot show a Live Activity. Run FlightSearchExample on an iPhone simulator."
            case .globalMaximumExceeded, .targetMaximumExceeded:
                return "End the Live Activity already on the Lock Screen, then track again."
            default:
                break
            }
        }
        let description = error.localizedDescription
        if description.isEmpty || description.hasPrefix("The operation couldn’t be completed") || description.hasPrefix("The operation couldn't be completed") {
            return "Couldn’t start the Live Activity."
        }
        return description
    }

    private func publish(_ state: FlightActivityAttributes.ContentState) async {
        guard let current = activity else {
            statusMessage = "Track the flight before changing its status."
            return
        }

        let content = ActivityContent(
            state: state,
            staleDate: state.phase.showsAsEnded ? nil : Date().addingTimeInterval(20 * 60)
        )
        if state.phase.showsAsEnded {
            activity = nil
            tokenTask?.cancel()
            await LiveActivityBridge.end(
                current,
                content: content,
                dismissalPolicy: .after(Date().addingTimeInterval(15 * 60))
            )
            isTracking = false
        } else {
            await LiveActivityBridge.update(current, content: content)
            isTracking = true
        }
        phase = state.phase
        statusMessage = state.statusLine
    }

    private func clear() async {
        let current = activity
        activity = nil
        tokenTask?.cancel()
        if let current {
            await LiveActivityBridge.end(current, content: nil, dismissalPolicy: .immediate)
        }
        isTracking = false
        phase = nil
        hasPushToken = false
        statusMessage = "Removed from the Lock Screen."
    }

    private func observePushToStart() {
        guard #available(iOS 17.2, *) else { return }
        pushToStartTask?.cancel()
        pushToStartTask = Task {
            for await _ in Activity<FlightActivityAttributes>.pushToStartTokenUpdates {
                guard !Task.isCancelled else { continue }
            }
        }
    }

    private func observePushToken(for activity: Activity<FlightActivityAttributes>) {
        tokenTask?.cancel()
        tokenTask = Task {
            for await tokenData in activity.pushTokenUpdates {
                guard !Task.isCancelled, !tokenData.isEmpty else { continue }
                hasPushToken = true
            }
        }
    }
    #endif
}

/// Applies a simulator `.apns` drop. The simulator delivers that file as a
/// normal notification, so the app turns `event` and `content-state` into the Live Activity.
public enum FlightActivitySimulatorBridge {
    public static func handle(userInfo: [AnyHashable: Any]) {
        #if os(iOS)
        let payload = Dictionary(uniqueKeysWithValues: userInfo.compactMap { key, value -> (String, Any)? in
            guard let key = key as? String else { return nil }
            return (key, value)
        })
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let push = try? FlightActivityPushDecoding.decode(data) else {
            return
        }
        Task { await FlightActivitySimulatorPush.apply(push) }
        #endif
    }
}

#if os(iOS)
private enum FlightActivitySimulatorPush {
    @MainActor
    static func apply(_ push: FlightActivityPush) async {
        let content = ActivityContent(
            state: push.contentState,
            staleDate: push.contentState.phase.showsAsEnded ? nil : Date().addingTimeInterval(20 * 60)
        )
        if push.event == "start" {
            guard let attributes = push.attributes else { return }
            for existing in Activity<FlightActivityAttributes>.activities {
                await LiveActivityBridge.end(existing, content: nil, dismissalPolicy: .immediate)
            }
            _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
            return
        }

        let dismissal = ActivityUIDismissalPolicy.after(Date().addingTimeInterval(15 * 60))
        for activity in Activity<FlightActivityAttributes>.activities {
            if push.event == "end" {
                await LiveActivityBridge.end(activity, content: content, dismissalPolicy: dismissal)
            } else {
                await LiveActivityBridge.update(activity, content: content)
            }
        }
    }
}

private struct LiveActivityBridge: @unchecked Sendable {
    let activity: Activity<FlightActivityAttributes>

    static func update(
        _ activity: Activity<FlightActivityAttributes>,
        content: ActivityContent<FlightActivityAttributes.ContentState>
    ) async {
        await LiveActivityBridge(activity: activity).activity.update(content)
    }

    static func end(
        _ activity: Activity<FlightActivityAttributes>,
        content: ActivityContent<FlightActivityAttributes.ContentState>?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        await LiveActivityBridge(activity: activity).activity.end(content, dismissalPolicy: dismissalPolicy)
    }
}
#endif
