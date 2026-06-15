//
//  Deep_TaskApp.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/27/25.
//

import SwiftUI
import CoreData

@main
struct Deep_TaskApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Initialize analytics and fire a single test event to verify the
        // Mixpanel connection. We'll expand instrumentation after confirming.
        AnalyticsService.shared.start()
        AnalyticsService.shared.track("App Launched")
        AnalyticsService.shared.flush()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
