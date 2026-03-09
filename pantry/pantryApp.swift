//
//  pantryApp.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-21.
//

import SwiftUI
import SwiftData

@main
struct PantryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PantryItem.self,
            Category.self,
            StorageLocation.self,
            ShoppingListItem.self,
            Receipt.self,
            ReceiptItem.self,
            BarcodeMapping.self,
            Recipe.self,
            RecipeIngredient.self,
            RecipeInstruction.self,
            RecipeCategory.self,
            RecipeTag.self,
            RecipeCookingNote.self,
            RecipeCollection.self,
            MealPlan.self,
            MealPlanEntry.self,
            MealPlanConstraintProfile.self,
            MealPlanGeneration.self,
            MealPlanEntryReason.self,
            MealPlanFeedback.self
        ])
        // Use an in-memory store when the app is launched by the UI-test runner.
        // This guarantees a clean, isolated data set for every test run and prevents
        // test data from polluting the on-device store (or vice-versa).
        let isUITesting = CommandLine.arguments.contains("-UITesting")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
