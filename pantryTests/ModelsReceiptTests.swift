//
//  ModelsReceiptTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

// MARK: - Receipt.itemCount

struct ReceiptItemCountTests {

    @Test func itemCount_returnsZeroWhenNoItemsAreAttached() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let receipt = Receipt(storeName: "Test Store")
        context.insert(receipt)

        #expect(receipt.itemCount == 0)
    }

    @Test func itemCount_returnsOneAfterOneItemIsAttached() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let receipt = Receipt(storeName: "Test Store")
        let item = ReceiptItem(name: "Milk", price: 3.99)
        context.insert(receipt)
        context.insert(item)
        item.receipt = receipt

        #expect(receipt.itemCount == 1)
    }

    @Test func itemCount_returnsCorrectCountForMultipleItems() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let receipt = Receipt(storeName: "Test Store")
        let items = ["Milk", "Bread", "Eggs"].map { ReceiptItem(name: $0) }
        context.insert(receipt)
        items.forEach { context.insert($0); $0.receipt = receipt }

        #expect(receipt.itemCount == 3)
    }
}

// MARK: - ReceiptItem defaults

struct ReceiptItemDefaultTests {

    @Test func receiptItem_defaultsToNotAddedToPantry() {
        let item = ReceiptItem(name: "Butter")
        #expect(item.isAddedToPantry == false)
    }

    @Test func receiptItem_defaultsToQuantityOfOne() {
        let item = ReceiptItem(name: "Butter")
        #expect(item.quantity == 1)
    }

    @Test func receiptItem_defaultsToUnitOfItem() {
        let item = ReceiptItem(name: "Butter")
        #expect(item.unit == "item")
    }
}
