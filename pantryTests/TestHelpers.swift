//
//  TestHelpers.swift
//  pantryTests
//

import Foundation
import SwiftData
@testable import pantry

/// Creates an isolated in-memory ModelContainer with the full app schema.
/// Each test should call this to get its own container — never share containers
/// between tests.
func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        PantryItem.self, Category.self, StorageLocation.self,
        ShoppingListItem.self, Receipt.self, ReceiptItem.self,
        BarcodeMapping.self, Recipe.self, RecipeIngredient.self,
        RecipeInstruction.self, RecipeCategory.self, RecipeTag.self,
        RecipeCookingNote.self, RecipeCollection.self
    ])
    return try ModelContainer(
        for: schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}
