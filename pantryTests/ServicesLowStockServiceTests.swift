//
//  ServicesLowStockServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

// MARK: - detectLowStockItems

struct DetectLowStockItemsTests {

    @Test func detectLowStockItems_returnsItemAtDefaultThresholdOfOne() {
        let item = PantryItem(name: "Butter", quantity: 1.0, unit: "lb")
        let result = LowStockService.detectLowStockItems(from: [item])
        #expect(result.count == 1)
    }

    @Test func detectLowStockItems_returnsItemBelowThreshold() {
        let item = PantryItem(name: "Milk", quantity: 0.5, unit: "gallon")
        let result = LowStockService.detectLowStockItems(from: [item])
        #expect(result.count == 1)
    }

    @Test func detectLowStockItems_excludesItemsAboveDefaultThreshold() {
        let item = PantryItem(name: "Rice", quantity: 5.0, unit: "lb")
        let result = LowStockService.detectLowStockItems(from: [item])
        #expect(result.isEmpty)
    }

    @Test func detectLowStockItems_excludesExpiredItems() {
        let expired = PantryItem(
            name: "Old Yogurt",
            quantity: 0.5,
            expirationDate: Date().addingTimeInterval(-86400)
        )
        let result = LowStockService.detectLowStockItems(from: [expired])
        #expect(result.isEmpty)
    }

    @Test func detectLowStockItems_returnsEmptyForEmptyPantry() {
        #expect(LowStockService.detectLowStockItems(from: []).isEmpty)
    }

    @Test func detectLowStockItems_respectsCustomThreshold() {
        let item = PantryItem(name: "Flour", quantity: 3.0, unit: "lb")
        let resultDefault = LowStockService.detectLowStockItems(from: [item])
        let resultCustom = LowStockService.detectLowStockItems(from: [item], threshold: 5.0)
        #expect(resultDefault.isEmpty)
        #expect(resultCustom.count == 1)
    }

    @Test func detectLowStockItems_separatesLowFromAdequateStock() {
        let low = PantryItem(name: "Eggs", quantity: 1.0, unit: "count")
        let adequate = PantryItem(name: "Pasta", quantity: 3.0, unit: "box")
        let result = LowStockService.detectLowStockItems(from: [low, adequate])
        #expect(result.count == 1)
        #expect(result[0].name == "Eggs")
    }
}

// MARK: - isAlreadyOnList

struct IsAlreadyOnListTests {

    @Test func isAlreadyOnList_returnsTrueForExactCaseInsensitiveMatch() {
        let pantryItem = PantryItem(name: "Whole Milk", quantity: 0.5, unit: "gallon")
        let listItem = ShoppingListItem(name: "whole milk")
        #expect(LowStockService.isAlreadyOnList(pantryItem, existingItems: [listItem]))
    }

    @Test func isAlreadyOnList_returnsTrueForUpperCaseMatch() {
        let pantryItem = PantryItem(name: "Butter", quantity: 0.5, unit: "lb")
        let listItem = ShoppingListItem(name: "BUTTER")
        #expect(LowStockService.isAlreadyOnList(pantryItem, existingItems: [listItem]))
    }

    @Test func isAlreadyOnList_returnsFalseWhenNotOnList() {
        let pantryItem = PantryItem(name: "Butter", quantity: 0.5, unit: "lb")
        let listItem = ShoppingListItem(name: "Milk")
        #expect(!LowStockService.isAlreadyOnList(pantryItem, existingItems: [listItem]))
    }

    @Test func isAlreadyOnList_returnsFalseForEmptyList() {
        let pantryItem = PantryItem(name: "Butter", quantity: 0.5, unit: "lb")
        #expect(!LowStockService.isAlreadyOnList(pantryItem, existingItems: []))
    }
}

// MARK: - addToShoppingList

struct AddToShoppingListTests {

    @Test func addToShoppingList_addsNewItemsAndReturnsThemInserted() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let lowItem = PantryItem(name: "Milk", quantity: 0.5, unit: "gallon")
        context.insert(lowItem)

        let added = LowStockService.addToShoppingList([lowItem], existingList: [], context: context)

        #expect(added.count == 1)
        #expect(added[0].name == "Milk")
        #expect(added[0].unit == "gallon")
    }

    @Test func addToShoppingList_skipsItemsAlreadyOnList() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let lowItem = PantryItem(name: "Milk", quantity: 0.5, unit: "gallon")
        let existingEntry = ShoppingListItem(name: "Milk")
        context.insert(lowItem)
        context.insert(existingEntry)

        let added = LowStockService.addToShoppingList(
            [lowItem], existingList: [existingEntry], context: context)

        #expect(added.isEmpty)
    }

    @Test func addToShoppingList_setsRelatedPantryItemID() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let lowItem = PantryItem(name: "Eggs", quantity: 1.0, unit: "count")
        context.insert(lowItem)

        let added = LowStockService.addToShoppingList([lowItem], existingList: [], context: context)

        #expect(added[0].relatedPantryItemID == lowItem.id)
    }

    @Test func addToShoppingList_assignsHighPriorityWhenQuantityIsZero() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let outOfStock = PantryItem(name: "Salt", quantity: 0.0, unit: "container")
        context.insert(outOfStock)

        let added = LowStockService.addToShoppingList(
            [outOfStock], existingList: [], context: context)

        #expect(added[0].priority == 2) // 2 = high
    }

    @Test func addToShoppingList_assignsMediumPriorityWhenQuantityIsLowButNotZero() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let lowItem = PantryItem(name: "Butter", quantity: 0.5, unit: "lb")
        context.insert(lowItem)

        let added = LowStockService.addToShoppingList([lowItem], existingList: [], context: context)

        #expect(added[0].priority == 1) // 1 = medium
    }

    @Test func addToShoppingList_copiesEstimatedPriceFromPantryItem() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let lowItem = PantryItem(name: "Milk", quantity: 0.5, unit: "gallon", price: 4.99)
        context.insert(lowItem)

        let added = LowStockService.addToShoppingList([lowItem], existingList: [], context: context)

        #expect(added[0].estimatedPrice == 4.99)
    }

    @Test func addToShoppingList_returnsEmptyForEmptyInput() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let result = LowStockService.addToShoppingList([], existingList: [], context: context)
        #expect(result.isEmpty)
    }
}
