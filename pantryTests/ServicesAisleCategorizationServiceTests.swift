//
//  AisleCategorizationServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

struct AisleCategorizationServiceTests {

    // MARK: - suggestAisleName (pure function, no container needed)

    @Test func suggestAisleName_forMilk_returnsDairy() {
        #expect(AisleCategorizationService.suggestAisleName(for: "milk") == "Dairy")
    }

    @Test func suggestAisleName_forEggs_returnsProteins() {
        #expect(AisleCategorizationService.suggestAisleName(for: "eggs") == "Proteins")
    }

    @Test func suggestAisleName_forApples_returnsProduce() {
        #expect(AisleCategorizationService.suggestAisleName(for: "Apples") == "Produce")
    }

    @Test func suggestAisleName_forChickenBreast_returnsProteins() {
        #expect(AisleCategorizationService.suggestAisleName(for: "chicken breast") == "Proteins")
    }

    @Test func suggestAisleName_forBakingSoda_returnsBaking() {
        #expect(AisleCategorizationService.suggestAisleName(for: "baking soda") == "Baking")
    }

    @Test func suggestAisleName_forFrozenPeas_returnsFrozen() {
        #expect(AisleCategorizationService.suggestAisleName(for: "frozen peas") == "Frozen")
    }

    @Test func suggestAisleName_forCannedTomatoes_returnsCanned() {
        #expect(AisleCategorizationService.suggestAisleName(for: "canned tomatoes") == "Canned")
    }

    @Test func suggestAisleName_forOliveOil_returnsCondiments() {
        // "olive" is not in map; "oil" → Condiments
        #expect(AisleCategorizationService.suggestAisleName(for: "olive oil") == "Condiments")
    }

    @Test func suggestAisleName_forCheddarCheese_returnsDairy() {
        #expect(AisleCategorizationService.suggestAisleName(for: "cheddar cheese") == "Dairy")
    }

    @Test func suggestAisleName_forBlackPepper_returnsSpices() {
        // "black" not in map; "pepper" → Spices
        #expect(AisleCategorizationService.suggestAisleName(for: "black pepper") == "Spices")
    }

    @Test func suggestAisleName_forUnknownItem_returnsNil() {
        #expect(AisleCategorizationService.suggestAisleName(for: "paper towels") == nil)
    }

    @Test func suggestAisleName_isCaseInsensitive() {
        #expect(AisleCategorizationService.suggestAisleName(for: "MILK") == "Dairy")
        #expect(AisleCategorizationService.suggestAisleName(for: "Chicken Breast") == "Proteins")
    }

    // MARK: - suggestCategory (requires Category objects)

    @Test func suggestCategory_returnsMatchingCategoryFromList() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let dairy   = Category(name: "Dairy",   colorHex: "#5AC8FA", iconName: "drop")
        let produce = Category(name: "Produce", colorHex: "#34C759", iconName: "leaf")
        context.insert(dairy)
        context.insert(produce)

        let result = AisleCategorizationService.suggestCategory(for: "milk", from: [dairy, produce])
        #expect(result?.name == "Dairy")
    }

    @Test func suggestCategory_returnsNilWhenNoMatchingCategoryInList() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let produce = Category(name: "Produce", colorHex: "#34C759", iconName: "leaf")
        context.insert(produce)

        // "milk" → "Dairy", but only Produce is in the list
        let result = AisleCategorizationService.suggestCategory(for: "milk", from: [produce])
        #expect(result == nil)
    }

    @Test func suggestCategory_returnsNilWhenCategoryListIsEmpty() {
        let result = AisleCategorizationService.suggestCategory(for: "milk", from: [])
        #expect(result == nil)
    }

    // MARK: - categorizeUncategorized (requires SwiftData)

    @Test func categorizeUncategorized_assignsCategoryToUntaggedItems() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let dairy = Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop")
        context.insert(dairy)

        let item = ShoppingListItem(name: "Milk")
        context.insert(item)

        AisleCategorizationService.categorizeUncategorized(items: [item], categories: [dairy])

        #expect(item.category?.name == "Dairy")
    }

    @Test func categorizeUncategorized_doesNotOverwriteExistingCategory() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let dairy   = Category(name: "Dairy",   colorHex: "#5AC8FA", iconName: "drop")
        let produce = Category(name: "Produce", colorHex: "#34C759", iconName: "leaf")
        context.insert(dairy)
        context.insert(produce)

        // Item named "Milk" but manually assigned to Produce
        let item = ShoppingListItem(name: "Milk", category: produce)
        context.insert(item)

        AisleCategorizationService.categorizeUncategorized(items: [item], categories: [dairy, produce])

        // Must remain Produce; must NOT be changed to Dairy
        #expect(item.category?.name == "Produce")
    }

    @Test func categorizeUncategorized_leavesItemNilWhenNameIsUnrecognized() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let dairy = Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop")
        context.insert(dairy)

        let item = ShoppingListItem(name: "paper towels")
        context.insert(item)

        AisleCategorizationService.categorizeUncategorized(items: [item], categories: [dairy])

        #expect(item.category == nil)
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([ShoppingListItem.self, Category.self, PantryItem.self])
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
