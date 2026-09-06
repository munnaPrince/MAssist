//
//  MassistApp.swift
//  Massist
//
//  Created by Munnaf Koilakuntla on 31/08/26.
//

import SwiftUI
import CoreData
import UserNotifications

final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

@main
struct MassistApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var workoutHistoryStore = WorkoutHistoryStore()
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    private let notificationDelegate = AppNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appTheme.colorScheme)
                .environmentObject(store)
                .environmentObject(workoutHistoryStore)
                .environment(\.managedObjectContext, CoreDataStack.shared.container.viewContext)
        }
    }
}
