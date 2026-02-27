//
//  ServicesRecipePantryServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

// MARK: - estimatedShelfLifeDays

struct EstimatedShelfLifeDaysTests {

    @Test func estimatedShelfLifeDays_returnsSevenDaysForProduce() {
        let category = Category(name: "Produce", colorHex: "#34C759", iconName: "leaf")
        #expect(RecipePantryService.estimatedShelfLifeDays(for: category) == 7)
    }

    @Test func estimatedShelfLifeDays_returnsFourteenDaysForDairy() {
        let category = Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop")
        #expect(RecipePantryService.estimatedShelfLifeDays(for: category) == 14)
    }

    @Test func estimatedShelfLifeDays_returnsThreeDaysForProteins() {
        let category = Category(name: "Proteins", colorHex: "#FF3B30", iconName: "flame")
        #expect(RecipePantryService.estimatedShelfLifeDays(for: category) == 3)
    }

    @Test func estimatedShelfLifeDays_returns180DaysForFrozen() {
        let category = Category(name: "Frozen", colorHex: "#64D2FF", iconName: "snowflake")
        #expect(RecipePantryService.estimatedShelfLifeDays(for: category) == 180)
    }

    @Test func estimatedShelfLifeDays_returns730DaysForCanned() {
        let category = Category(name: "Canned", colorHex: "#BF5AF2", iconName: "cylinder")
        #expect(RecipePantryService.estimatedShelfLifeDays(for: category) == 730)
    }

    @Test func estimatedShelfLifeDays_isCaseInsensitive() {
        let lower = Category(name: "produce", colorHex: "#34C759", iconName: "leaf")
        let upper = Category(name: "PRODUCE", colorHex: "#34C759", iconName: "leaf")
        #expect(RecipePantryService.estimatedShelfLifeDays(for: lower) == 7)
        #expect(RecipePantryService.estimatedShelfLifeDays(for: upper) == 7)
    }

    @Test func estimatedShelfLifeDays_returnsNilForUnknownCategory() {
        let custom = Category(name: "My Special Sauce", colorHex: "#FF0000", iconName: "star")
        #expect(RecipePantryService.estimatedShelfLifeDays(for: custom) == nil)
    }
}

// MARK: - Unit Conversion (no models needed)

struct ConvertQuantityTests {

    @Test func convertQuantity_returnsSameAmountWhenUnitsMatch() {
        let result = RecipePantryService.convertQuantity(from: "cup", to: "cup", quantity: 3)
        #expect(result == 3)
    }

    @Test func convertQuantity_convertsCupsToTablespoons() {
        // 1 cup = 240 mL, 1 tbsp = 15 mL → 1 cup = 16 tbsp
        let result = RecipePantryService.convertQuantity(from: "cup", to: "tbsp", quantity: 1)
        #expect(result == 240.0 / 15.0)
    }

    @Test func convertQuantity_convertsKilogramsToGrams() {
        let result = RecipePantryService.convertQuantity(from: "kg", to: "g", quantity: 1)
        #expect(result == 1000)
    }

    @Test func convertQuantity_convertsPoundsToGrams() {
        let result = RecipePantryService.convertQuantity(from: "lb", to: "g", quantity: 1)
        #expect(abs(result - 453.592) < 0.001)
    }

    @Test func convertQuantity_returnsOriginalQuantityForUnknownUnits() {
        let result = RecipePantryService.convertQuantity(from: "pinch", to: "handful", quantity: 5)
        #expect(result == 5)
    }

    @Test func convertQuantity_isCaseInsensitive() {
        let lower = RecipePantryService.convertQuantity(from: "cup", to: "tbsp", quantity: 1)
        let upper = RecipePantryService.convertQuantity(from: "CUP", to: "TBSP", quantity: 1)
        #expect(lower == upper)
    }
}

// MARK: - isIngredientAvailable (no container needed — only reads name/quantity)

struct IsIngredientAvailableTests {

    @Test func isIngredientAvailable_returnsTrueForExactNameMatch() {
        let ingredient = RecipeIngredient(name: "eggs", quantity: 2, unit: "count")
        let pantryItem = PantryItem(name: "eggs", quantity: 6, unit: "count")

        #expect(RecipePantryService.isIngredientAvailable(ingredient: ingredient, pantryItems: [pantryItem]))
    }

    @Test func isIngredientAvailable_isCaseInsensitiveForExactMatch() {
        let ingredient = RecipeIngredient(name: "Eggs", quantity: 2, unit: "count")
        let pantryItem = PantryItem(name: "eggs", quantity: 6, unit: "count")

        #expect(RecipePantryService.isIngredientAvailable(ingredient: ingredient, pantryItems: [pantryItem]))
    }

    @Test func isIngredientAvailable_returnsTrueWhenPantryItemNameContainsIngredientName() {
        let ingredient = RecipeIngredient(name: "milk", quantity: 1, unit: "cup")
        let pantryItem = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")

        #expect(RecipePantryService.isIngredientAvailable(ingredient: ingredient, pantryItems: [pantryItem]))
    }

    @Test func isIngredientAvailable_returnsTrueForReverseFuzzyMatch() {
        let ingredient = RecipeIngredient(name: "chicken breast", quantity: 1, unit: "lb")
        let pantryItem = PantryItem(name: "chicken", quantity: 2, unit: "lb")

        #expect(RecipePantryService.isIngredientAvailable(ingredient: ingredient, pantryItems: [pantryItem]))
    }

    @Test func isIngredientAvailable_returnsFalseWhenQuantityIsZero() {
        let ingredient = RecipeIngredient(name: "butter", quantity: 1, unit: "tbsp")
        let pantryItem = PantryItem(name: "butter", quantity: 0, unit: "lb")

        #expect(!RecipePantryService.isIngredientAvailable(ingredient: ingredient, pantryItems: [pantryItem]))
    }

    @Test func isIngredientAvailable_returnsFalseWhenIngredientNotInPantry() {
        let ingredient = RecipeIngredient(name: "truffle oil", quantity: 1, unit: "tbsp")
        let pantryItem = PantryItem(name: "olive oil", quantity: 1, unit: "bottle")

        #expect(!RecipePantryService.isIngredientAvailable(ingredient: ingredient, pantryItems: [pantryItem]))
    }

    @Test func isIngredientAvailable_returnsFalseForEmptyPantry() {
        let ingredient = RecipeIngredient(name: "flour", quantity: 2, unit: "cup")

        #expect(!RecipePantryService.isIngredientAvailable(ingredient: ingredient, pantryItems: []))
    }
}

// MARK: - findMatchingPantryItem (no container needed)

struct FindMatchingPantryItemTests {

    @Test func findMatchingPantryItem_returnsExactMatchFirst() {
        let ingredient = RecipeIngredient(name: "butter", quantity: 2, unit: "tbsp")
        let exactItem = PantryItem(name: "butter", quantity: 1, unit: "lb")
        let fuzzyItem = PantryItem(name: "peanut butter", quantity: 1, unit: "jar")

        let result = RecipePantryService.findMatchingPantryItem(for: ingredient, in: [fuzzyItem, exactItem])
        #expect(result?.name == "butter")
    }

    @Test func findMatchingPantryItem_returnsFuzzyMatchWhenNoExactMatch() {
        let ingredient = RecipeIngredient(name: "milk", quantity: 1, unit: "cup")
        let pantryItem = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")

        let result = RecipePantryService.findMatchingPantryItem(for: ingredient, in: [pantryItem])
        #expect(result != nil)
    }

    @Test func findMatchingPantryItem_returnsNilWhenNoMatch() {
        let ingredient = RecipeIngredient(name: "saffron", quantity: 1, unit: "pinch")
        let pantryItem = PantryItem(name: "salt", quantity: 1, unit: "container")

        let result = RecipePantryService.findMatchingPantryItem(for: ingredient, in: [pantryItem])
        #expect(result == nil)
    }
}

// MARK: - findSubstitutions (no container needed)

struct FindSubstitutionsTests {

    @Test func findSubstitutions_returnsPantryItemsThatAreValidSubstitutes() {
        let ingredient = RecipeIngredient(name: "butter", quantity: 1, unit: "cup")
        let margarine = PantryItem(name: "margarine", quantity: 1, unit: "lb")
        let coconutOil = PantryItem(name: "coconut oil", quantity: 1, unit: "jar")
        let saltItem = PantryItem(name: "salt", quantity: 1, unit: "container")

        let results = RecipePantryService.findSubstitutions(for: ingredient, in: [margarine, coconutOil, saltItem])
        let names = results.map(\.name)
        #expect(names.contains("margarine"))
        #expect(names.contains("coconut oil"))
        #expect(!names.contains("salt"))
    }

    @Test func findSubstitutions_returnsEmptyArrayWhenNoSubstitutesInPantry() {
        let ingredient = RecipeIngredient(name: "butter", quantity: 1, unit: "cup")
        let pantryItem = PantryItem(name: "salt", quantity: 1, unit: "container")

        let results = RecipePantryService.findSubstitutions(for: ingredient, in: [pantryItem])
        #expect(results.isEmpty)
    }

    @Test func findSubstitutions_returnsEmptyForIngredientWithNoKnownSubstitutes() {
        let ingredient = RecipeIngredient(name: "saffron", quantity: 1, unit: "pinch")
        let pantryItem = PantryItem(name: "turmeric", quantity: 1, unit: "jar")

        let results = RecipePantryService.findSubstitutions(for: ingredient, in: [pantryItem])
        #expect(results.isEmpty)
    }
}

// MARK: - checkRecipeMakeable (container needed for relationship access)

struct CheckRecipeMakeableTests {

    @Test func checkRecipeMakeable_returns100PercentWhenRecipeHasNoIngredients() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let recipe = Recipe(name: "Water", prepTime: 0, cookTime: 0)
        context.insert(recipe)
        // No ingredients added — relationship stays nil

        let result = RecipePantryService.checkRecipeMakeable(recipe: recipe, pantryItems: [])
        #expect(result.matchPercentage == 100.0)
        #expect(result.missingIngredients.isEmpty)
        #expect(result.availableIngredients.isEmpty)
    }

    @Test func checkRecipeMakeable_returns100PercentWhenAllIngredientsAreAvailable() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Scrambled Eggs", prepTime: 5, cookTime: 5)
        let ingredient = RecipeIngredient(name: "eggs", quantity: 3, unit: "count")
        let pantryItem = PantryItem(name: "eggs", quantity: 12, unit: "count")

        context.insert(recipe)
        context.insert(ingredient)
        context.insert(pantryItem)
        ingredient.recipe = recipe

        let result = RecipePantryService.checkRecipeMakeable(recipe: recipe, pantryItems: [pantryItem])
        #expect(result.matchPercentage == 100.0)
        #expect(result.missingIngredients.isEmpty)
    }

    @Test func checkRecipeMakeable_returns50PercentWhenHalfOfIngredientsAreMissing() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Carbonara", prepTime: 10, cookTime: 20)
        let eggs = RecipeIngredient(name: "eggs", quantity: 3, unit: "count")
        let pancetta = RecipeIngredient(name: "pancetta", quantity: 100, unit: "g")
        let eggsInPantry = PantryItem(name: "eggs", quantity: 6, unit: "count")

        context.insert(recipe)
        context.insert(eggs)
        context.insert(pancetta)
        context.insert(eggsInPantry)
        eggs.recipe = recipe
        pancetta.recipe = recipe

        let result = RecipePantryService.checkRecipeMakeable(recipe: recipe, pantryItems: [eggsInPantry])
        #expect(result.matchPercentage == 50.0)
        #expect(result.missingIngredients.count == 1)
        #expect(result.missingIngredients[0].name == "pancetta")
        #expect(result.availableIngredients.count == 1)
    }

    @Test func checkRecipeMakeable_returns0PercentWhenNothingIsAvailable() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Steak", prepTime: 5, cookTime: 15)
        let steak = RecipeIngredient(name: "ribeye steak", quantity: 1, unit: "lb")
        let butter = RecipeIngredient(name: "butter", quantity: 2, unit: "tbsp")

        context.insert(recipe)
        context.insert(steak)
        context.insert(butter)
        steak.recipe = recipe
        butter.recipe = recipe

        let result = RecipePantryService.checkRecipeMakeable(recipe: recipe, pantryItems: [])
        #expect(result.matchPercentage == 0.0)
        #expect(result.missingIngredients.count == 2)
    }
}

// MARK: - generateShoppingList

struct GenerateShoppingListTests {

    @Test func generateShoppingList_containsOnlyMissingIngredients() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Pasta", prepTime: 10, cookTime: 20)
        let pasta = RecipeIngredient(name: "pasta", quantity: 2, unit: "cup")
        let sauce = RecipeIngredient(name: "tomato sauce", quantity: 1, unit: "can")
        let pastaInPantry = PantryItem(name: "pasta", quantity: 1, unit: "bag")

        context.insert(recipe)
        context.insert(pasta)
        context.insert(sauce)
        context.insert(pastaInPantry)
        pasta.recipe = recipe
        sauce.recipe = recipe

        let list = RecipePantryService.generateShoppingList(recipe: recipe, pantryItems: [pastaInPantry])
        #expect(list.count == 1)
        #expect(list[0].name == "tomato sauce")
    }

    @Test func generateShoppingList_isEmptyWhenAllIngredientsAreAvailable() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Toast", prepTime: 2, cookTime: 3)
        let bread = RecipeIngredient(name: "bread", quantity: 2, unit: "slice")
        let breadInPantry = PantryItem(name: "bread", quantity: 1, unit: "loaf")

        context.insert(recipe)
        context.insert(bread)
        context.insert(breadInPantry)
        bread.recipe = recipe

        let list = RecipePantryService.generateShoppingList(recipe: recipe, pantryItems: [breadInPantry])
        #expect(list.isEmpty)
    }

    @Test func generateShoppingList_scaleFactorMultipliesMissingQuantities() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Pancakes", prepTime: 5, cookTime: 15, servings: 4)
        let flour = RecipeIngredient(name: "flour", quantity: 1, unit: "cup")

        context.insert(recipe)
        context.insert(flour)
        flour.recipe = recipe

        let list = RecipePantryService.generateShoppingList(recipe: recipe, pantryItems: [], scaleFactor: 2.0)
        #expect(list.count == 1)
        #expect(list[0].quantity == 2.0)
    }
}

// MARK: - deductIngredientsFromPantry

struct DeductIngredientsFromPantryTests {

    @Test func deductIngredientsFromPantry_reducesQuantityByIngredientAmount() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Omelette", prepTime: 5, cookTime: 5)
        let eggs = RecipeIngredient(name: "eggs", quantity: 3, unit: "count")
        let eggsInPantry = PantryItem(name: "eggs", quantity: 12, unit: "count")

        context.insert(recipe)
        context.insert(eggs)
        context.insert(eggsInPantry)
        eggs.recipe = recipe

        _ = RecipePantryService.deductIngredientsFromPantry(
            recipe: recipe,
            pantryItems: [eggsInPantry],
            modelContext: context
        )

        #expect(eggsInPantry.quantity == 9)
    }

    @Test func deductIngredientsFromPantry_doesNotGoBelowZero() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Big Batch", prepTime: 5, cookTime: 30)
        let flour = RecipeIngredient(name: "flour", quantity: 10, unit: "cup")
        let flourInPantry = PantryItem(name: "flour", quantity: 2, unit: "cup")

        context.insert(recipe)
        context.insert(flour)
        context.insert(flourInPantry)
        flour.recipe = recipe

        _ = RecipePantryService.deductIngredientsFromPantry(
            recipe: recipe,
            pantryItems: [flourInPantry],
            modelContext: context
        )

        #expect(flourInPantry.quantity == 0)
    }

    @Test func deductIngredientsFromPantry_appliesScaleFactor() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Cookies", prepTime: 15, cookTime: 12, servings: 12)
        let butter = RecipeIngredient(name: "butter", quantity: 1, unit: "cup")
        let butterInPantry = PantryItem(name: "butter", quantity: 3, unit: "cup")

        context.insert(recipe)
        context.insert(butter)
        context.insert(butterInPantry)
        butter.recipe = recipe

        _ = RecipePantryService.deductIngredientsFromPantry(
            recipe: recipe,
            pantryItems: [butterInPantry],
            scaleFactor: 2.0,
            modelContext: context
        )

        #expect(butterInPantry.quantity == 1) // 3 - (1 * 2.0) = 1
    }

    @Test func deductIngredientsFromPantry_updatesModifiedDate() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let before = Date()
        let recipe = Recipe(name: "Soup", prepTime: 10, cookTime: 30)
        let carrot = RecipeIngredient(name: "carrot", quantity: 2, unit: "count")
        let carrotInPantry = PantryItem(name: "carrot", quantity: 5, unit: "count")

        context.insert(recipe)
        context.insert(carrot)
        context.insert(carrotInPantry)
        carrot.recipe = recipe

        _ = RecipePantryService.deductIngredientsFromPantry(
            recipe: recipe,
            pantryItems: [carrotInPantry],
            modelContext: context
        )

        #expect(carrotInPantry.modifiedDate >= before)
    }
}

// MARK: - suggestRecipesForExpiringItems

struct SuggestRecipesForExpiringItemsTests {

    @Test func suggestRecipesForExpiringItems_returnsRecipesThatUseExpiringIngredients() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Milk Toast", prepTime: 5, cookTime: 5)
        let milkIngredient = RecipeIngredient(name: "milk", quantity: 1, unit: "cup")
        let expiringMilk = PantryItem(
            name: "Whole Milk",
            expirationDate: Date().addingTimeInterval(2 * 86400)
        )

        context.insert(recipe)
        context.insert(milkIngredient)
        context.insert(expiringMilk)
        milkIngredient.recipe = recipe

        let results = RecipePantryService.suggestRecipesForExpiringItems(
            recipes: [recipe],
            expiringItems: [expiringMilk]
        )

        #expect(results.count == 1)
        #expect(results[0].recipe.name == "Milk Toast")
        #expect(results[0].expiringIngredientsUsed.count == 1)
    }

    @Test func suggestRecipesForExpiringItems_excludesRecipesThatDontUseExpiringItems() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let recipe = Recipe(name: "Steak", prepTime: 5, cookTime: 15)
        let steakIngredient = RecipeIngredient(name: "ribeye", quantity: 1, unit: "lb")
        let expiringMilk = PantryItem(
            name: "Whole Milk",
            expirationDate: Date().addingTimeInterval(86400)
        )

        context.insert(recipe)
        context.insert(steakIngredient)
        context.insert(expiringMilk)
        steakIngredient.recipe = recipe

        let results = RecipePantryService.suggestRecipesForExpiringItems(
            recipes: [recipe],
            expiringItems: [expiringMilk]
        )

        #expect(results.isEmpty)
    }

    @Test func suggestRecipesForExpiringItems_sortsByMostExpiringIngredientsUsed() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Recipe 1 uses 1 expiring item
        let recipe1 = Recipe(name: "Simple", prepTime: 5, cookTime: 5)
        let r1Milk = RecipeIngredient(name: "milk", quantity: 1, unit: "cup")

        // Recipe 2 uses 2 expiring items
        let recipe2 = Recipe(name: "Complex", prepTime: 10, cookTime: 20)
        let r2Milk = RecipeIngredient(name: "milk", quantity: 1, unit: "cup")
        let r2Butter = RecipeIngredient(name: "butter", quantity: 2, unit: "tbsp")

        let expiringMilk = PantryItem(name: "milk", expirationDate: Date().addingTimeInterval(86400))
        let expiringButter = PantryItem(name: "butter", expirationDate: Date().addingTimeInterval(86400))

        context.insert(recipe1); context.insert(recipe2)
        context.insert(r1Milk); context.insert(r2Milk); context.insert(r2Butter)
        context.insert(expiringMilk); context.insert(expiringButter)
        r1Milk.recipe = recipe1
        r2Milk.recipe = recipe2
        r2Butter.recipe = recipe2

        let results = RecipePantryService.suggestRecipesForExpiringItems(
            recipes: [recipe1, recipe2],
            expiringItems: [expiringMilk, expiringButter]
        )

        #expect(results.count == 2)
        #expect(results[0].recipe.name == "Complex") // 2 expiring items used
        #expect(results[1].recipe.name == "Simple")  // 1 expiring item used
    }
}
