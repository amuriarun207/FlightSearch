import Foundation
import Testing
import FlightActivityAttributes

struct FlightActivityPayloadTests {
    @Test func simulatorFilesMatchTheFlightStatusModel() throws {
        let directory = payloadDirectory()
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "apns" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        #expect(files.map(\.lastPathComponent) == [
            "01-start-scheduled.apns",
            "02-boarding.apns",
            "03-departed.apns",
            "04-in-flight.apns",
            "05-delayed.apns",
            "06-landed.apns",
            "07-cancelled.apns",
        ])

        let expected: [FlightPhase] = [.scheduled, .boarding, .departed, .inFlight, .delayed, .landed, .cancelled]
        var previousTimestamp: TimeInterval = 0
        for (file, phase) in zip(files, expected) {
            let data = try Data(contentsOf: file)
            let bundle = try targetBundle(in: data)
            #expect(bundle == "com.learning.FlightSearchExample")
            let push = try FlightActivityPushDecoding.decode(data)
            #expect(push.contentState == phase.sampleContent)
            #expect(push.timestamp > previousTimestamp)
            previousTimestamp = push.timestamp
            if phase == .scheduled {
                #expect(push.event == "start")
                #expect(push.attributes == .simulatorSample)
            } else if phase.showsAsEnded {
                #expect(push.event == "end")
            } else {
                #expect(push.event == "update")
            }
        }
    }

    @Test func flightNumberIsStableForARoute() {
        #expect(FlightActivityAttributes.flightNumber(originCode: "DXB", destinationCode: "LHR") == "FS552")
    }

    private func payloadDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("FlightSearchExample/LiveActivityPayloads", isDirectory: true)
    }

    private func targetBundle(in data: Data) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data)
        let dictionary = try #require(object as? [String: Any])
        return try #require(dictionary["Simulator Target Bundle"] as? String)
    }
}
