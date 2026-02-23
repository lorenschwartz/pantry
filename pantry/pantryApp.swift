//
//  pantryApp.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-21.
//

import SwiftUI
import SwiftData

@main
struct pantryApp: App {
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
            RecipeCollection.self
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
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
