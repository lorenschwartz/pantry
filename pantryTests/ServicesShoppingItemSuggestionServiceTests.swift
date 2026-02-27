//
//  ServicesShoppingItemSuggestionServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

// MARK: - suggestions(for:pantryItems:shoppingHistory:)

struct SuggestionsQueryTests {

    @Test func suggestions_emptyQueryReturnsEmpty() {
        let item = PantryItem(name: "Milk", quantity: 1, unit: "gallon")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "", pantryItems: [item], shoppingHistory: [])
        #expect(result.isEmpty)
    }

    @Test func suggestions_whitespaceOnlyQueryReturnsEmpty() {
        let item = PantryItem(name: "Milk", quantity: 1, unit: "gallon")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "   ", pantryItems: [item], shoppingHistory: [])
        #expect(result.isEmpty)
    }

    @Test func suggestions_returnsMatchingPantryItem() {
        let milk = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")
        let eggs = PantryItem(name: "Eggs", quantity: 12, unit: "count")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [milk, eggs], shoppingHistory: [])
        #expect(result.count == 1)
        #expect(result[0].name == "Whole Milk")
        #expect(result[0].source == .pantry)
    }

    @Test func suggestions_isCaseInsensitive() {
        let item = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")
        let lower = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [item], shoppingHistory: [])
        let upper = ShoppingItemSuggestionService.suggestions(
            for: "MILK", pantryItems: [item], shoppingHistory: [])
        let mixed = ShoppingItemSuggestionService.suggestions(
            for: "MiLk", pantryItems: [item], shoppingHistory: [])
        #expect(lower.count == 1)
        #expect(upper.count == 1)
        #expect(mixed.count == 1)
    }

    @Test func suggestions_returnsMatchingHistoryItem() {
        let listItem = ShoppingListItem(name: "Almond Milk", quantity: 1, unit: "carton")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "almond", pantryItems: [], shoppingHistory: [listItem])
        #expect(result.count == 1)
        #expect(result[0].name == "Almond Milk")
        #expect(result[0].source == .history)
    }

    @Test func suggestions_returnsBothSourcesWhenDifferentNames() {
        let pantryItem = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")
        let historyItem = ShoppingListItem(name: "Skim Milk", quantity: 1, unit: "gallon")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [pantryItem], shoppingHistory: [historyItem])
        #expect(result.count == 2)
    }

    @Test func suggestions_deduplicatesByNameCaseInsensitive() {
        let pantryItem = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")
        let historyItem = ShoppingListItem(name: "whole milk", quantity: 2, unit: "gallon")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [pantryItem], shoppingHistory: [historyItem])
        #expect(result.count == 1)
    }

    @Test func suggestions_prefersPantrySourceWhenNameMatches() {
        let pantryItem = PantryItem(name: "Milk", quantity: 1, unit: "gallon", price: 4.99)
        let historyItem = ShoppingListItem(name: "Milk", quantity: 3, unit: "bottle")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [pantryItem], shoppingHistory: [historyItem])
        #expect(result.count == 1)
        #expect(result[0].source == .pantry)
        #expect(result[0].estimatedPrice == 4.99)
    }

    @Test func suggestions_respectsMaxResults() {
        let items = (1...10).map { PantryItem(name: "Item\($0)", quantity: 1, unit: "pc") }
        let result = ShoppingItemSuggestionService.suggestions(
            for: "item", pantryItems: items, shoppingHistory: [], maxResults: 3)
        #expect(result.count == 3)
    }

    @Test func suggestions_ranksPrefixMatchBeforeSubstringMatch() {
        let prefix = PantryItem(name: "Milk", quantity: 1, unit: "gallon")
        let substring = PantryItem(name: "Almond Milk", quantity: 1, unit: "carton")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [substring, prefix], shoppingHistory: [])
        #expect(result[0].name == "Milk")
        #expect(result[1].name == "Almond Milk")
    }

    @Test func suggestions_sortsAlphabeticallyWithinSameTier() {
        let b = PantryItem(name: "Butter", quantity: 1, unit: "lb")
        let a = PantryItem(name: "Almond Butter", quantity: 1, unit: "jar")
        let c = PantryItem(name: "Cashew Butter", quantity: 1, unit: "jar")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "butter", pantryItems: [c, b, a], shoppingHistory: [])
        // "Butter" is a prefix match → first; then alphabetical: "Almond Butter", "Cashew Butter"
        #expect(result[0].name == "Butter")
        #expect(result[1].name == "Almond Butter")
        #expect(result[2].name == "Cashew Butter")
    }

    @Test func suggestions_copiesPantryPrice() {
        let item = PantryItem(name: "Olive Oil", quantity: 1, unit: "bottle", price: 12.99)
        let result = ShoppingItemSuggestionService.suggestions(
            for: "olive", pantryItems: [item], shoppingHistory: [])
        #expect(result[0].estimatedPrice == 12.99)
    }

    @Test func suggestions_returnsEmptyWhenNoItemsMatch() {
        let item = PantryItem(name: "Butter", quantity: 1, unit: "lb")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [item], shoppingHistory: [])
        #expect(result.isEmpty)
    }

    @Test func suggestions_excludesArchivedPantryItems() {
        var archived = PantryItem(name: "Milk", quantity: 1, unit: "gallon")
        archived.isArchived = true
        let result = ShoppingItemSuggestionService.suggestions(
            for: "milk", pantryItems: [archived], shoppingHistory: [])
        #expect(result.isEmpty)
    }

    @Test func suggestions_usesAtLeastOneForPantryQuantity() {
        // Pantry items at very low stock should suggest buying at least 1
        let item = PantryItem(name: "Salt", quantity: 0.1, unit: "container")
        let result = ShoppingItemSuggestionService.suggestions(
            for: "salt", pantryItems: [item], shoppingHistory: [])
        #expect(result[0].quantity >= 1)
    }
}

// MARK: - recentItems(from:limit:)

struct RecentItemsTests {

    @Test func recentItems_returnsEmptyForEmptyHistory() {
        #expect(ShoppingItemSuggestionService.recentItems(from: []).isEmpty)
    }

    @Test func recentItems_returnsItemsFromHistory() {
        let item = ShoppingListItem(name: "Butter", quantity: 1, unit: "lb")
        let result = ShoppingItemSuggestionService.recentItems(from: [item])
        #expect(result.count == 1)
        #expect(result[0].name == "Butter")
    }

    @Test func recentItems_deduplicatesByNameCaseInsensitive() {
        let first = ShoppingListItem(name: "Milk", quantity: 1, unit: "gallon")
        let duplicate = ShoppingListItem(name: "milk", quantity: 2, unit: "bottle")
        let result = ShoppingItemSuggestionService.recentItems(from: [first, duplicate])
        #expect(result.count == 1)
    }

    @Test func recentItems_respectsLimit() {
        let items = (1...10).map { ShoppingListItem(name: "Item\($0)", quantity: 1, unit: "pc") }
        let result = ShoppingItemSuggestionService.recentItems(from: items, limit: 3)
        #expect(result.count == 3)
    }

    @Test func recentItems_preservesHistoryOrder() {
        // The caller passes items sorted by addedDate desc; service preserves that order
        let first = ShoppingListItem(name: "First", quantity: 1, unit: "item")
        let second = ShoppingListItem(name: "Second", quantity: 1, unit: "item")
        let result = ShoppingItemSuggestionService.recentItems(from: [first, second])
        #expect(result[0].name == "First")
        #expect(result[1].name == "Second")
    }

    @Test func recentItems_copiesPrice() {
        let item = ShoppingListItem(name: "Coffee", quantity: 1, unit: "bag", estimatedPrice: 14.99)
        let result = ShoppingItemSuggestionService.recentItems(from: [item])
        #expect(result[0].estimatedPrice == 14.99)
    }
}
