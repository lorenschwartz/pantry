//
//  ServicesBarcodeServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

struct BarcodeServiceTests {

    // MARK: - lookupMapping

    @Test func lookupMapping_returnsNilWhenBarcodeNotFound() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let result = BarcodeService.lookupMapping(for: "000000000000", context: context)

        #expect(result == nil)
    }

    @Test func lookupMapping_returnsMappingWhenBarcodeExists() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "012345678901", productName: "Whole Milk")
        context.insert(mapping)

        let result = BarcodeService.lookupMapping(for: "012345678901", context: context)

        #expect(result != nil)
        #expect(result?.productName == "Whole Milk")
    }

    @Test func lookupMapping_doesNotReturnMappingForDifferentBarcode() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "012345678901", productName: "Whole Milk")
        context.insert(mapping)

        let result = BarcodeService.lookupMapping(for: "999999999999", context: context)

        #expect(result == nil)
    }

    // MARK: - autoFillFields: name

    @Test func autoFillFields_populatesEmptyName() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Orange Juice")
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.name == "Orange Juice")
    }

    @Test func autoFillFields_doesNotOverwriteExistingName() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Orange Juice")
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "My OJ", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.name == "My OJ")
    }

    // MARK: - autoFillFields: brand

    @Test func autoFillFields_populatesEmptyBrand() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk", brand: "Organic Valley")
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.brand == "Organic Valley")
    }

    @Test func autoFillFields_doesNotOverwriteExistingBrand() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk", brand: "Organic Valley")
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "My Brand", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.brand == "My Brand")
    }

    @Test func autoFillFields_leavesEmptyBrandWhenMappingHasNoBrand() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Generic Item", brand: nil)
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.brand == "")
    }

    // MARK: - autoFillFields: unit

    @Test func autoFillFields_populatesUnitWhenCurrentIsItemAndMappingDiffers() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk", defaultUnit: "gallon")
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.unit == "gallon")
    }

    @Test func autoFillFields_doesNotOverwriteCustomUnit() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk", defaultUnit: "gallon")
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "lb",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.unit == "lb")
    }

    @Test func autoFillFields_keepsItemUnitWhenMappingAlsoHasItem() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Widget", defaultUnit: "item")
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.unit == "item")
    }

    // MARK: - autoFillFields: category

    @Test func autoFillFields_populatesCategoryWhenNoneSelected() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let dairy = Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop", isDefault: true, sortOrder: 1)
        context.insert(dairy)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk")
        mapping.category = dairy
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.category?.name == "Dairy")
    }

    @Test func autoFillFields_doesNotOverwriteExistingCategory() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let dairy = Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop", isDefault: true, sortOrder: 1)
        let produce = Category(name: "Produce", colorHex: "#34C759", iconName: "leaf", isDefault: true, sortOrder: 0)
        context.insert(dairy)
        context.insert(produce)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk")
        mapping.category = dairy
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: produce, currentPrice: ""
        )

        #expect(result.category?.name == "Produce")
    }

    // MARK: - autoFillFields: price

    @Test func autoFillFields_populatesEmptyPrice() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk", averagePrice: 3.99)
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.price == "3.99")
    }

    @Test func autoFillFields_doesNotOverwriteExistingPrice() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk", averagePrice: 3.99)
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: "2.50"
        )

        #expect(result.price == "2.50")
    }

    @Test func autoFillFields_leavesEmptyPriceWhenMappingHasNone() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "1", productName: "Milk", averagePrice: nil)
        context.insert(mapping)

        let result = BarcodeService.autoFillFields(
            from: mapping,
            currentName: "", currentBrand: "", currentUnit: "item",
            currentCategory: nil, currentPrice: ""
        )

        #expect(result.price == "")
    }

    // MARK: - learnBarcode

    @Test func learnBarcode_createsNewMappingForUnknownBarcode() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        BarcodeService.learnBarcode(
            "012345678901",
            productName: "Whole Milk",
            brand: "Organic Valley",
            unit: "gallon",
            category: nil,
            price: 5.99,
            context: context
        )

        let result = BarcodeService.lookupMapping(for: "012345678901", context: context)
        #expect(result != nil)
        #expect(result?.productName == "Whole Milk")
        #expect(result?.brand == "Organic Valley")
        #expect(result?.defaultUnit == "gallon")
        #expect(result?.averagePrice == 5.99)
    }

    @Test func learnBarcode_newMappingStartsWithTimesScannedOfOne() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        BarcodeService.learnBarcode(
            "012345678901",
            productName: "Whole Milk",
            brand: nil,
            unit: "item",
            category: nil,
            price: nil,
            context: context
        )

        let result = BarcodeService.lookupMapping(for: "012345678901", context: context)
        #expect(result?.timesScanned == 1)
    }

    @Test func learnBarcode_incrementsTimesScannedForExistingBarcode() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let existing = BarcodeMapping(barcode: "012345678901", productName: "Whole Milk")
        context.insert(existing)

        BarcodeService.learnBarcode(
            "012345678901",
            productName: "Whole Milk",
            brand: nil,
            unit: "item",
            category: nil,
            price: nil,
            context: context
        )

        #expect(existing.timesScanned == 2)
    }

    @Test func learnBarcode_doesNotCreateDuplicateMappingForSameBarcode() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        BarcodeService.learnBarcode(
            "012345678901",
            productName: "Whole Milk",
            brand: nil,
            unit: "item",
            category: nil,
            price: nil,
            context: context
        )
        BarcodeService.learnBarcode(
            "012345678901",
            productName: "Whole Milk",
            brand: nil,
            unit: "item",
            category: nil,
            price: nil,
            context: context
        )

        let descriptor = FetchDescriptor<BarcodeMapping>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 1)
    }

    @Test func learnBarcode_preservesExistingMappingDataWhenBarcodeAlreadyKnown() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let existing = BarcodeMapping(
            barcode: "012345678901",
            productName: "Whole Milk",
            brand: "Organic Valley",
            defaultUnit: "gallon",
            averagePrice: 5.99
        )
        context.insert(existing)

        BarcodeService.learnBarcode(
            "012345678901",
            productName: "Different Name",
            brand: nil,
            unit: "item",
            category: nil,
            price: nil,
            context: context
        )

        // Existing mapping data should be unchanged; only timesScanned increments
        #expect(existing.productName == "Whole Milk")
        #expect(existing.brand == "Organic Valley")
        #expect(existing.defaultUnit == "gallon")
        #expect(existing.averagePrice == 5.99)
    }
}
