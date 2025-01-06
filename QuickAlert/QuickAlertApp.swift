//
//  QuickAlertApp.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 6/19/24.
//

import SwiftUI
import SwiftData

@main
struct QuickAlertApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // App initialization
    init() {
        FileLogger.shared.ensureLogFileExists() // Ensures the log file is created when the app starts
    }

    var body: some Scene {
        WindowGroup {
            CourseAndProfileView() // invoking course and profile view
            }
    }
        
}
