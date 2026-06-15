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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
