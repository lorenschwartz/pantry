//
//  ServicesReceiptScanServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

struct ReceiptScanServiceTests {

    // Fixture: a realistic supermarket receipt in OCR form
    private let basicReceiptOCR = """
    WHOLE FOODS MARKET
    123 Main Street
    (415) 555-1234
    03/01/2026
    ORGANIC WHOLE MILK        5.99
    SOURDOUGH BREAD           4.50
    CAGE FREE EGGS 12CT       6.99
    OLIVE OIL 500ML          12.99
    SUBTOTAL                 30.47
    TAX                       2.74
    TOTAL                    33.21
    """

    // MARK: - extractPrice

    @Test func extractPrice_parsesTrailingPrice() {
        let price = ReceiptScanService.extractPrice(from: "ORGANIC WHOLE MILK        5.99")
        #expect(price == 5.99)
    }

    @Test func extractPrice_parsesDollarSignPrefix() {
        let price = ReceiptScanService.extractPrice(from: "BREAD          $4.50")
        #expect(price == 4.50)
    }

    @Test func extractPrice_returnsNilForLineWithNoPrice() {
        let price = ReceiptScanService.extractPrice(from: "WHOLE FOODS MARKET")
        #expect(price == nil)
    }

    @Test func extractPrice_returnsNilWhenValueExceedsMaximum() {
        // 4-digit amounts (≥ 1000) should be rejected to avoid matching totals/SKUs
        let price = ReceiptScanService.extractPrice(from: "SAVINGS TOTAL   1000.00")
        #expect(price == nil)
    }

    // MARK: - normalizeName

    @Test func normalizeName_titleCasesAllCapsInput() {
        let name = ReceiptScanService.normalizeName("ORGANIC WHOLE MILK")
        #expect(name == "Organic Whole Milk")
    }

    @Test func normalizeName_stripsLeadingNumericCodes() {
        let name = ReceiptScanService.normalizeName("123 FLOUR 5LB")
        #expect(name != nil)
        #expect(name?.hasPrefix("123") == false)
    }

    @Test func normalizeName_returnsNilForShortFragments() {
        let name = ReceiptScanService.normalizeName("AB")
        #expect(name == nil)
    }

    // MARK: - extractStoreName

    @Test func extractStoreName_returnsFirstMeaningfulLine() {
        let lines = ["WHOLE FOODS MARKET", "123 Main Street", "ORGANIC MILK  5.99"]
        let store = ReceiptScanService.extractStoreName(from: lines)
        #expect(store == "Whole Foods Market")
    }

    @Test func extractStoreName_returnsNilForEmptyInput() {
        let store = ReceiptScanService.extractStoreName(from: [])
        #expect(store == nil)
    }

    // MARK: - extractDate

    @Test func extractDate_parsesSlashFormattedDate() {
        let lines = ["WHOLE FOODS", "03/01/2026", "MILK  5.99"]
        let date = ReceiptScanService.extractDate(from: lines)
        #expect(date != nil)
        let components = Calendar.current.dateComponents([.month, .day, .year], from: date!)
        #expect(components.month == 3)
        #expect(components.day == 1)
        #expect(components.year == 2026)
    }

    @Test func extractDate_returnsNilWhenNoDatesFound() {
        let date = ReceiptScanService.extractDate(from: ["STORE NAME", "MILK  5.99", "TOTAL  5.99"])
        #expect(date == nil)
    }

    // MARK: - extractTotal

    @Test func extractTotal_parsesTotalKeyword() {
        let lines = ["SUBTOTAL  30.47", "TAX  2.74", "TOTAL  33.21"]
        let total = ReceiptScanService.extractTotal(from: lines)
        #expect(total == 33.21)
    }

    @Test func extractTotal_prefersTotalOverSubtotal() {
        let lines = ["SUBTOTAL  30.47", "TOTAL  33.21"]
        let total = ReceiptScanService.extractTotal(from: lines)
        #expect(total == 33.21)
    }

    @Test func extractTotal_handlesGrandTotalLabel() {
        // Receipts often print "GRAND TOTAL" or "TOTAL DUE" — substring match must cover these
        let lines = ["SUBTOTAL  30.47", "GRAND TOTAL  33.21"]
        let total = ReceiptScanService.extractTotal(from: lines)
        #expect(total == 33.21)
    }

    // MARK: - extractLineItems

    @Test func extractLineItems_detectsBasicItemsWithPrices() {
        let lines = [
            "WHOLE FOODS MARKET",
            "ORGANIC WHOLE MILK        5.99",
            "SOURDOUGH BREAD           4.50",
            "TOTAL                    10.49"
        ]
        let items = ReceiptScanService.extractLineItems(from: lines)
        #expect(items.count == 2)
        #expect(items.allSatisfy { $0.price != nil })
    }

    @Test func extractLineItems_excludesTaxLines() {
        let lines = [
            "ORGANIC MILK     5.99",
            "TAX              0.54",
            "TOTAL            6.53"
        ]
        let items = ReceiptScanService.extractLineItems(from: lines)
        #expect(items.count == 1)
        #expect(items[0].name.lowercased().contains("milk"))
    }

    @Test func extractLineItems_allItemsAreSelectedByDefault() {
        let lines = ["ORGANIC MILK  5.99", "BREAD  4.50"]
        let items = ReceiptScanService.extractLineItems(from: lines)
        #expect(items.allSatisfy { $0.isSelected })
    }

    // MARK: - parse(ocrText:)

    @Test func parse_extractsStoreNameFromBasicReceipt() {
        let result = ReceiptScanService.parse(ocrText: basicReceiptOCR)
        #expect(result.storeName != nil)
        #expect(result.storeName?.localizedCaseInsensitiveContains("whole foods") == true)
    }

    @Test func parse_extractsTotalFromBasicReceipt() {
        let result = ReceiptScanService.parse(ocrText: basicReceiptOCR)
        #expect(result.totalAmount == 33.21)
    }

    @Test func parse_extractsLineItemsFromBasicReceipt() {
        let result = ReceiptScanService.parse(ocrText: basicReceiptOCR)
        // Expect Milk, Bread, Eggs, Olive Oil — not tax/subtotal/total lines
        #expect(result.lines.count >= 3)
    }

    @Test func parse_rawOCRTextIsPreserved() {
        let result = ReceiptScanService.parse(ocrText: basicReceiptOCR)
        #expect(result.rawOCRText == basicReceiptOCR)
    }

    @Test func parse_returnsEmptyLinesForBlankText() {
        let result = ReceiptScanService.parse(ocrText: "")
        #expect(result.lines.isEmpty)
    }

    // MARK: - saveReceipt (requires ModelContext)

    @Test func saveReceipt_insertsReceiptWithCorrectFields() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let purchaseDate = Date(timeIntervalSince1970: 1_740_787_200)
        let parsed = ParsedReceipt(
            storeName: "Trader Joe's",
            purchaseDate: purchaseDate,
            totalAmount: 22.50,
            lines: [
                ParsedReceiptLine(name: "Bananas", price: 1.29),
                ParsedReceiptLine(name: "Oat Milk", price: 3.99)
            ],
            rawOCRText: "TRADER JOE'S\nBANANAS  1.29\nOAT MILK  3.99\nTOTAL  22.50"
        )

        let receipt = ReceiptScanService.saveReceipt(parsed, image: nil, context: context)
        let fetched = try context.fetch(FetchDescriptor<Receipt>())
        #expect(fetched.count == 1)
        #expect(fetched[0].storeName == "Trader Joe's")
        #expect(fetched[0].totalAmount == 22.50)
        #expect(fetched[0].items?.count == 2)
        _ = receipt // suppress unused warning
    }

    @Test func saveReceipt_insertsOnlySelectedItems() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let parsed = ParsedReceipt(
            storeName: nil,
            purchaseDate: nil,
            totalAmount: nil,
            lines: [
                ParsedReceiptLine(name: "Milk",  price: 3.99, isSelected: true),
                ParsedReceiptLine(name: "Juice", price: 4.99, isSelected: false)
            ],
            rawOCRText: ""
        )

        ReceiptScanService.saveReceipt(parsed, image: nil, context: context)
        let fetched = try context.fetch(FetchDescriptor<Receipt>())
        #expect(fetched[0].items?.count == 1)
        #expect(fetched[0].items?[0].name == "Milk")
    }

    // MARK: - addReceiptItemToPantry

    @Test func addReceiptItemToPantry_createsPantryItemAndLinksIt() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let receipt = Receipt(storeName: "Safeway", purchaseDate: Date(), totalAmount: 10.0)
        let receiptItem = ReceiptItem(name: "Cheddar Cheese", price: 5.99)
        context.insert(receipt)
        context.insert(receiptItem)
        receiptItem.receipt = receipt

        ReceiptScanService.addReceiptItemToPantry(receiptItem, receipt: receipt, context: context)

        let pantryItems = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(pantryItems.count == 1)
        #expect(pantryItems[0].name == "Cheddar Cheese")
        #expect(pantryItems[0].price == 5.99)
        #expect(receiptItem.isAddedToPantry == true)
        #expect(receiptItem.pantryItem != nil)
    }

    @Test func addReceiptItemToPantry_preservesPurchaseDateFromReceipt() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let purchaseDate = Date(timeIntervalSince1970: 1_740_787_200)
        let receipt = Receipt(storeName: "Safeway", purchaseDate: purchaseDate)
        let receiptItem = ReceiptItem(name: "Eggs")
        context.insert(receipt)
        context.insert(receiptItem)
        receiptItem.receipt = receipt

        ReceiptScanService.addReceiptItemToPantry(receiptItem, receipt: receipt, context: context)

        let pantryItems = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(pantryItems[0].purchaseDate == purchaseDate)
    }

    @Test func addReceiptItemToPantry_isIdempotent() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let receipt = Receipt(storeName: "Costco")
        let receiptItem = ReceiptItem(name: "Olive Oil", price: 12.99)
        context.insert(receipt)
        context.insert(receiptItem)
        receiptItem.receipt = receipt

        // Call twice — should still produce only one PantryItem
        ReceiptScanService.addReceiptItemToPantry(receiptItem, receipt: receipt, context: context)
        ReceiptScanService.addReceiptItemToPantry(receiptItem, receipt: receipt, context: context)

        let pantryItems = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(pantryItems.count == 1)
    }

    // MARK: - addAllItemsToPantry

    @Test func addAllItemsToPantry_addsOnlyUnadded() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let receipt = Receipt(storeName: "Target")
        let item1 = ReceiptItem(name: "Butter", price: 4.99, isAddedToPantry: false)
        let item2 = ReceiptItem(name: "Bread",  price: 3.49, isAddedToPantry: true) // already added
        context.insert(receipt)
        context.insert(item1)
        context.insert(item2)
        item1.receipt = receipt
        item2.receipt = receipt
        receipt.items = [item1, item2]

        ReceiptScanService.addAllItemsToPantry(receipt: receipt, context: context)

        let pantryItems = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(pantryItems.count == 1)
        #expect(pantryItems[0].name == "Butter")
    }
}
