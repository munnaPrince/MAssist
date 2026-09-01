//
//  MassistApp.swift
//  Massist
//
//  Created by Munnaf Koilakuntla on 31/08/26.
//

import SwiftUI
import CoreData

@main
struct MassistApp: App {
    @StateObject private var store = AppStore()
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appTheme.colorScheme)
                .environmentObject(store)
                .environment(\.managedObjectContext, CoreDataStack.shared.container.viewContext)
        }
    }
}
