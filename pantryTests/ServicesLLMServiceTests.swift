//
//  ServicesLLMServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

// MARK: - LLMToolFormatter Tests

struct LLMToolFormatterTests {

    // MARK: - pantryItemsJSON

    @Test func pantryItemsJSON_handlesEmptyArray() {
        let json = LLMToolFormatter.pantryItemsJSON([])
        #expect(json == "[]")
    }

    @Test func pantryItemsJSON_containsItemName() {
        let item = PantryItem(name: "Test Apple", quantity: 3, unit: "count")
        let json = LLMToolFormatter.pantryItemsJSON([item])
        #expect(json.contains("Test Apple"))
    }

    @Test func pantryItemsJSON_containsQuantityAndUnit() {
        let item = PantryItem(name: "Sugar", quantity: 2.5, unit: "kg")
        let json = LLMToolFormatter.pantryItemsJSON([item])
        #expect(json.contains("kg"))
    }

    @Test func pantryItemsJSON_includesExpirationFlag() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let item = PantryItem(name: "Milk", quantity: 1, unit: "gallon", expirationDate: pastDate)
        let json = LLMToolFormatter.pantryItemsJSON([item])
        #expect(json.contains("is_expired"))
    }

    @Test func pantryItemsJSON_includesBrandWhenPresent() {
        let item = PantryItem(name: "Cheese", quantity: 1, unit: "lb", brand: "Tillamook")
        let json = LLMToolFormatter.pantryItemsJSON([item])
        #expect(json.contains("Tillamook"))
    }

    @Test func pantryItemsJSON_handlesMultipleItems() {
        let items = [
            PantryItem(name: "Eggs", quantity: 12, unit: "count"),
            PantryItem(name: "Butter", quantity: 1, unit: "lb")
        ]
        let json = LLMToolFormatter.pantryItemsJSON(items)
        #expect(json.contains("Eggs"))
        #expect(json.contains("Butter"))
    }

    // MARK: - recipesJSON

    @Test func recipesJSON_handlesEmptyArray() {
        let json = LLMToolFormatter.recipesJSON([])
        #expect(json == "[]")
    }

    @Test func recipesJSON_containsRecipeName() {
        let recipe = Recipe(name: "Test Pasta", prepTime: 10, cookTime: 20, servings: 2)
        let json = LLMToolFormatter.recipesJSON([recipe])
        #expect(json.contains("Test Pasta"))
    }

    @Test func recipesJSON_containsDifficultyAndServings() {
        let recipe = Recipe(name: "Easy Salad", prepTime: 5, cookTime: 0, servings: 4, difficulty: .easy)
        let json = LLMToolFormatter.recipesJSON([recipe])
        #expect(json.contains("Easy"))
    }

    @Test func recipesJSON_includesFavoriteFlag() {
        let recipe = Recipe(name: "Fav Recipe", prepTime: 10, cookTime: 30, servings: 2, isFavorite: true)
        let json = LLMToolFormatter.recipesJSON([recipe])
        #expect(json.contains("is_favorite"))
    }

    // MARK: - recipeDetailJSON

    @Test func recipeDetailJSON_containsNameAndTimes() {
        let recipe = Recipe(name: "Spaghetti", prepTime: 10, cookTime: 20, servings: 4)
        let json = LLMToolFormatter.recipeDetailJSON(recipe)
        #expect(json.contains("Spaghetti"))
        #expect(json.contains("prep_time_minutes"))
        #expect(json.contains("cook_time_minutes"))
    }

    @Test func recipeDetailJSON_containsIngredientsList() {
        let recipe = Recipe(name: "Test Recipe", prepTime: 5, cookTime: 10, servings: 2)
        let json = LLMToolFormatter.recipeDetailJSON(recipe)
        #expect(json.contains("ingredients"))
        #expect(json.contains("instructions"))
    }

    // MARK: - shoppingItemsJSON

    @Test func shoppingItemsJSON_handlesEmptyArray() {
        let json = LLMToolFormatter.shoppingItemsJSON([])
        #expect(json == "[]")
    }

    @Test func shoppingItemsJSON_containsItemName() {
        let item = ShoppingListItem(name: "Butter", quantity: 1, unit: "lb")
        let json = LLMToolFormatter.shoppingItemsJSON([item])
        #expect(json.contains("Butter"))
    }

    @Test func shoppingItemsJSON_showsCheckedState_whenChecked() {
        let item = ShoppingListItem(name: "Milk", quantity: 1, unit: "gallon", isChecked: true)
        let json = LLMToolFormatter.shoppingItemsJSON([item])
        #expect(json.contains("is_checked"))
        #expect(json.contains("true"))
    }

    @Test func shoppingItemsJSON_showsCheckedState_whenUnchecked() {
        let item = ShoppingListItem(name: "Eggs", quantity: 12, unit: "count", isChecked: false)
        let json = LLMToolFormatter.shoppingItemsJSON([item])
        #expect(json.contains("is_checked"))
        #expect(json.contains("false"))
    }

    @Test func shoppingItemsJSON_includesPriority() {
        let item = ShoppingListItem(name: "Coffee", quantity: 1, unit: "bag", priority: 2)
        let json = LLMToolFormatter.shoppingItemsJSON([item])
        #expect(json.contains("priority"))
    }

    // MARK: - expiringItemsJSON

    @Test func expiringItemsJSON_returnsOnlyExpiringItems() {
        let expiringItem = PantryItem(
            name: "Cheese",
            quantity: 0.5,
            unit: "lb",
            expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
        let freshItem = PantryItem(
            name: "Pasta",
            quantity: 1,
            unit: "box",
            expirationDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())
        )
        let json = LLMToolFormatter.expiringItemsJSON([expiringItem, freshItem])
        #expect(json.contains("Cheese"))
        #expect(!json.contains("Pasta"))
    }

    @Test func expiringItemsJSON_includesExpiredItems() {
        let expiredItem = PantryItem(
            name: "Old Milk",
            quantity: 1,
            unit: "gallon",
            expirationDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )
        let json = LLMToolFormatter.expiringItemsJSON([expiredItem])
        #expect(json.contains("Old Milk"))
        #expect(json.contains("is_expired"))
    }

    @Test func expiringItemsJSON_handlesItemWithNoExpiration() {
        let item = PantryItem(name: "Rice", quantity: 5, unit: "lb")
        // No expiration date — should not appear in expiring items
        let json = LLMToolFormatter.expiringItemsJSON([item])
        #expect(json == "[]" || !json.contains("Rice"))
    }
}

// MARK: - LLM Service Configuration Tests

@MainActor
struct LLMServiceConfigurationTests {

    @Test func init_defaultsToBalancedProfile() {
        let service = LLMService()
        #expect(service.modelProfile == .balanced)
        #expect(service.modelID == "claude-sonnet-4-5")
    }

    @Test func normalizeAssistantResponse_stripsCommonMarkdownArtifacts() {
        let input = """
        ## Dinner ideas
        - Use almonds
        - Make pesto
        ```swift
        print("x")
        ```
        """
        let normalized = LLMService.normalizeAssistantResponse(input)
        #expect(!normalized.contains("##"))
        #expect(!normalized.contains("```"))
        #expect(normalized.contains("Dinner ideas"))
    }

    @Test func systemPrompt_enforcesPlainTextResponses() {
        let service = LLMService()
        #expect(service.systemPrompt.contains("Return plain text only"))
        #expect(service.systemPrompt.contains("Do not use Markdown"))
    }
}
