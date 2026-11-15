//
//  FlightSearchExampleApp.swift
//  FlightSearchExample
//
//  Created by Arun kumar on 18/10/2026.
//

import FlightSearchKit
import SwiftUI
import SwiftData
import UIKit
import UserNotifications

@main
struct FlightSearchExampleApp: App {
    @UIApplicationDelegateAdaptor(FlightSearchAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class FlightSearchAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { _, _ in
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        FlightActivitySimulatorBridge.handle(userInfo: notification.request.content.userInfo)
        return [.banner, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        FlightActivitySimulatorBridge.handle(userInfo: response.notification.request.content.userInfo)
    }
}
