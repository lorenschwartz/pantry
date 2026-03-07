//
//  ServicesReceiptParsingServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

// MARK: - extractStoreName

struct ExtractStoreNameTests {

    @Test func extractStoreName_returnsFirstNonEmptyLine() {
        let text = "WHOLE FOODS MARKET\n123 Main Street\nItem  3.99"
        #expect(ReceiptParsingService.extractStoreName(from: text) == "WHOLE FOODS MARKET")
    }

    @Test func extractStoreName_returnsNilForEmptyText() {
        #expect(ReceiptParsingService.extractStoreName(from: "") == nil)
    }

    @Test func extractStoreName_skipsLeadingBlankLines() {
        let text = "\n\nTARGET\nsome address\n"
        #expect(ReceiptParsingService.extractStoreName(from: text) == "TARGET")
    }

    @Test func extractStoreName_skipsLinesOfOnlyDigitsAndSeparators() {
        let text = "01/15/2026\nALDI\nMilk  1.99"
        // The date-only first line should be skipped; "ALDI" returned
        let result = ReceiptParsingService.extractStoreName(from: text)
        #expect(result == "ALDI")
    }
}

// MARK: - extractPurchaseDate

struct ExtractPurchaseDateTests {

    @Test func extractPurchaseDate_parsesMMSlashDDSlashYYYY() {
        let text = "STORE\n01/15/2026\nMilk  3.99"
        let date = ReceiptParsingService.extractPurchaseDate(from: text)
        #expect(date != nil)
        let comps = Calendar.current.dateComponents([.month, .day, .year], from: date!)
        #expect(comps.month == 1)
        #expect(comps.day == 15)
        #expect(comps.year == 2026)
    }

    @Test func extractPurchaseDate_parsesMMDashDDDashYYYY() {
        let text = "STORE\n03-22-2026\nBread  4.50"
        let date = ReceiptParsingService.extractPurchaseDate(from: text)
        #expect(date != nil)
        let comps = Calendar.current.dateComponents([.month, .day, .year], from: date!)
        #expect(comps.month == 3)
        #expect(comps.day == 22)
        #expect(comps.year == 2026)
    }

    @Test func extractPurchaseDate_expandsTwoDigitYear() {
        let text = "STORE\n06/10/26\nEggs  5.99"
        let date = ReceiptParsingService.extractPurchaseDate(from: text)
        #expect(date != nil)
        let comps = Calendar.current.dateComponents([.year], from: date!)
        #expect(comps.year == 2026)
    }

    @Test func extractPurchaseDate_returnsNilWhenNoDatesFound() {
        let text = "WHOLE FOODS\nOrganic Milk  3.99\nTOTAL  3.99"
        #expect(ReceiptParsingService.extractPurchaseDate(from: text) == nil)
    }
}

// MARK: - parseLineAsItem

struct ParseLineAsItemTests {

    @Test func parseLineAsItem_parsesNameAndPriceFromSimpleLine() {
        let result = ReceiptParsingService.parseLineAsItem("Organic Milk  3.99")
        #expect(result != nil)
        #expect(result?.price == 3.99)
        #expect(result?.name.lowercased().contains("milk") == true)
    }

    @Test func parseLineAsItem_returnsNilForLineWithoutPrice() {
        #expect(ReceiptParsingService.parseLineAsItem("WHOLE FOODS MARKET") == nil)
    }

    @Test func parseLineAsItem_returnsNilForTotalLine() {
        #expect(ReceiptParsingService.parseLineAsItem("TOTAL  15.56") == nil)
    }

    @Test func parseLineAsItem_returnsNilForTaxLine() {
        #expect(ReceiptParsingService.parseLineAsItem("TAX  1.08") == nil)
    }

    @Test func parseLineAsItem_returnsNilForSubtotalLine() {
        #expect(ReceiptParsingService.parseLineAsItem("SUBTOTAL  14.48") == nil)
    }

    @Test func parseLineAsItem_returnsNilForDateOnlyLine() {
        #expect(ReceiptParsingService.parseLineAsItem("01/15/2026") == nil)
    }

    @Test func parseLineAsItem_parsesQuantityAndUnitFromName() {
        let result = ReceiptParsingService.parseLineAsItem("Bananas  1.2 LB  0.89")
        #expect(result != nil)
        #expect(result?.quantity == 1.2)
        #expect(result?.unit == "lb")
    }

    @Test func parseLineAsItem_defaultsToQuantityOneAndUnitItemWhenNoUnitPresent() {
        let result = ReceiptParsingService.parseLineAsItem("Sourdough Bread  4.50")
        #expect(result?.quantity == 1.0)
        #expect(result?.unit == "item")
    }

    @Test func parseLineAsItem_doesNotSkipItemNameContainingKeywordWord() {
        // "TOTAL FAGE" is a brand name, not a total line — should parse as item
        let result = ReceiptParsingService.parseLineAsItem("TOTAL FAGE GREEK YOGURT  1.29")
        #expect(result != nil)
        #expect(result?.price == 1.29)
    }
}

// MARK: - parseReceiptText

struct ParseReceiptTextTests {

    @Test func parseReceiptText_returnsEmptyArrayForEmptyText() {
        #expect(ReceiptParsingService.parseReceiptText("").isEmpty)
    }

    @Test func parseReceiptText_returnsEmptyArrayForSingleHeaderLine() {
        #expect(ReceiptParsingService.parseReceiptText("WHOLE FOODS MARKET").isEmpty)
    }

    @Test func parseReceiptText_skipsFirstLineAsStoreName() {
        // "WHOLE FOODS" is a valid-looking item name but must be skipped as the header
        let text = "WHOLE FOODS\nOrganic Milk  3.99"
        let items = ReceiptParsingService.parseReceiptText(text)
        #expect(items.count == 1)
        #expect(items[0].name.lowercased().contains("milk") == true)
    }

    @Test func parseReceiptText_excludesTotalLine() {
        let text = "STORE\nMilk  3.99\nTOTAL  3.99"
        let items = ReceiptParsingService.parseReceiptText(text)
        #expect(!items.map { $0.name.uppercased() }.contains("TOTAL"))
    }

    @Test func parseReceiptText_excludesTaxLine() {
        let text = "STORE\nMilk  3.99\nTAX  0.32"
        let items = ReceiptParsingService.parseReceiptText(text)
        #expect(!items.map { $0.name.uppercased() }.contains("TAX"))
    }

    @Test func parseReceiptText_parsesThreeItemReceipt() {
        let text = """
        WHOLE FOODS
        Organic Milk  3.99
        Sourdough Bread  4.50
        Free Range Eggs  5.99
        SUBTOTAL  14.48
        TAX  1.08
        TOTAL  15.56
        """
        let items = ReceiptParsingService.parseReceiptText(text)
        #expect(items.count == 3)
    }

    @Test func parseReceiptText_preservesPricesForEachItem() {
        let text = "STORE\nMilk  3.99\nBread  4.50"
        let items = ReceiptParsingService.parseReceiptText(text)
        let prices = items.compactMap(\.price).sorted()
        #expect(prices == [3.99, 4.50])
    }
}

// MARK: - matchReceiptItem

struct MatchReceiptItemTests {

    @Test func matchReceiptItem_returnsNilWhenPantryIsEmpty() {
        let item = ParsedReceiptItem(name: "Whole Milk", quantity: 1, unit: "item", price: 3.99)
        #expect(ReceiptParsingService.matchReceiptItem(item, to: []) == nil)
    }

    @Test func matchReceiptItem_returnsExactCaseInsensitiveMatch() {
        let item = ParsedReceiptItem(name: "WHOLE MILK", quantity: 1, unit: "item", price: 3.99)
        let pantryItem = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")
        let result = ReceiptParsingService.matchReceiptItem(item, to: [pantryItem])
        #expect(result?.name == "Whole Milk")
    }

    @Test func matchReceiptItem_returnsFuzzyMatchWhenPantryNameContainsReceiptName() {
        let item = ParsedReceiptItem(name: "Milk", quantity: 1, unit: "item", price: 3.99)
        let pantryItem = PantryItem(name: "Organic Whole Milk", quantity: 1, unit: "gallon")
        let result = ReceiptParsingService.matchReceiptItem(item, to: [pantryItem])
        #expect(result != nil)
    }

    @Test func matchReceiptItem_returnsFuzzyMatchWhenReceiptNameContainsPantryName() {
        let item = ParsedReceiptItem(name: "Organic 2% Milk", quantity: 1, unit: "item", price: 3.99)
        let pantryItem = PantryItem(name: "milk", quantity: 1, unit: "gallon")
        let result = ReceiptParsingService.matchReceiptItem(item, to: [pantryItem])
        #expect(result != nil)
    }

    @Test func matchReceiptItem_returnsNilWhenNoMatchFound() {
        let item = ParsedReceiptItem(name: "Sriracha Hot Sauce", quantity: 1, unit: "item", price: 2.99)
        let pantryItem = PantryItem(name: "Ketchup", quantity: 1, unit: "bottle")
        #expect(ReceiptParsingService.matchReceiptItem(item, to: [pantryItem]) == nil)
    }

    @Test func matchReceiptItem_prefersExactMatchOverFuzzy() {
        let item = ParsedReceiptItem(name: "Butter", quantity: 1, unit: "item", price: 4.99)
        let exactItem = PantryItem(name: "Butter", quantity: 1, unit: "lb")
        let fuzzyItem = PantryItem(name: "Peanut Butter", quantity: 1, unit: "jar")
        let result = ReceiptParsingService.matchReceiptItem(item, to: [fuzzyItem, exactItem])
        #expect(result?.name == "Butter")
    }
}
