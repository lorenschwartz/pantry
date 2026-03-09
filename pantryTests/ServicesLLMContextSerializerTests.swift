//
//  ServicesLLMContextSerializerTests.swift
//  pantryTests
//

import Testing
@testable import pantry

struct LLMContextSerializerTests {

    @Test func pantryItemsSummaryJSON_excludesSensitiveFieldsByDefault() {
        let item = PantryItem(
            name: "Almonds",
            quantity: 1,
            unit: "bag",
            price: 7.99,
            notes: "Bought at specialty store"
        )
        let json = LLMContextSerializer.pantryItemsSummaryJSON([item])
        #expect(json.contains("Almonds"))
        #expect(!json.contains("Bought at specialty store"))
        #expect(!json.contains("7.99"))
    }

    @Test func pantryItemsSummaryJSON_includesSensitiveFieldsWhenRequested() {
        let item = PantryItem(
            name: "Almonds",
            quantity: 1,
            unit: "bag",
            price: 7.99,
            notes: "Bought at specialty store"
        )
        let json = LLMContextSerializer.pantryItemsSummaryJSON([item], includeSensitiveNotes: true)
        #expect(json.contains("Bought at specialty store"))
        #expect(json.contains("7.99"))
    }

    @Test func shoppingItemsSummaryJSON_excludesNotesAndPriceByDefault() {
        let item = ShoppingListItem(
            name: "Olive Oil",
            quantity: 1,
            unit: "bottle",
            notes: "Get extra virgin",
            estimatedPrice: 15.50
        )
        let json = LLMContextSerializer.shoppingItemsSummaryJSON([item])
        #expect(json.contains("Olive Oil"))
        #expect(!json.contains("Get extra virgin"))
        #expect(!json.contains("15.5"))
    }

    @Test func recipesSummaryJSON_excludesDescriptionByDefault() {
        let recipe = Recipe(
            name: "Spicy Noodles",
            description: "Detailed private family adaptation notes",
            prepTime: 10,
            cookTime: 10,
            servings: 2
        )
        let json = LLMContextSerializer.recipesSummaryJSON([recipe])
        #expect(json.contains("Spicy Noodles"))
        #expect(!json.contains("family adaptation notes"))
    }

    @Test func pantryItemsSummaryJSON_respectsMaxItemsLimit() {
        let items = (1...5).map { PantryItem(name: "Item \($0)", quantity: 1, unit: "item") }
        let json = LLMContextSerializer.pantryItemsSummaryJSON(items, maxItems: 2)
        #expect(json.contains("Item 1"))
        #expect(json.contains("Item 2"))
        #expect(!json.contains("Item 3"))
    }
}

