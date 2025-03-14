//
//  Memory_MatchersApp.swift
//  Memory Matchers
//
//  Created by Justin Whitt on 3/8/25.
//

import SwiftUI
import SwiftData

@main
struct Memory_MatchersApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Score.self, // Include Score model
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            print("ModelContainer successfully initialized!")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer) // Inject SwiftData ModelContainer
        }
    }
}
