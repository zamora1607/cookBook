//
//  cookBookApp.swift
//  cookBook
//
//  Created by Ania on 31/12/2024.
//

import SwiftUI
import SwiftData

@main
struct cookBookApp: App {
    @StateObject private var localization = AppLocalization.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self,
            Ingredient.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localization)
                .environment(\.locale, Locale(identifier: localization.selectedLanguage.rawValue))
        }
        .modelContainer(sharedModelContainer)
    }
}
