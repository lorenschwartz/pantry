//
//  BarcodeService.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import Foundation
import SwiftData

/// Service for barcode lookup and learning operations.
class BarcodeService {

    // MARK: - Lookup

    /// Returns the stored `BarcodeMapping` for `barcode`, or `nil` if none exists.
    static func lookupMapping(for barcode: String, context: ModelContext) -> BarcodeMapping? {
        let descriptor = FetchDescriptor<BarcodeMapping>(
            predicate: #Predicate { $0.barcode == barcode }
        )
        return try? context.fetch(descriptor).first
    }

    // MARK: - Auto-fill

    /// Merges known mapping data into the current add/edit form state.
    ///
    /// Each field is only replaced when it still holds its default or empty value,
    /// so any value the user has already entered is preserved.
    ///
    /// - Returns: Updated (name, brand, unit, category, price) tuple.
    static func autoFillFields(
        from mapping: BarcodeMapping,
        currentName: String,
        currentBrand: String,
        currentUnit: String,
        currentCategory: Category?,
        currentPrice: String
    ) -> (name: String, brand: String, unit: String, category: Category?, price: String) {
        let name = currentName.isEmpty ? mapping.productName : currentName

        let brand: String
        if currentBrand.isEmpty, let mappedBrand = mapping.brand {
            brand = mappedBrand
        } else {
            brand = currentBrand
        }

        let unit = (currentUnit == "item" && mapping.defaultUnit != "item")
            ? mapping.defaultUnit
            : currentUnit

        let category = currentCategory ?? mapping.category

        let price: String
        if currentPrice.isEmpty, let avg = mapping.averagePrice {
            price = String(format: "%.2f", avg)
        } else {
            price = currentPrice
        }

        return (name, brand, unit, category, price)
    }

    // MARK: - Learning

    /// Creates a new `BarcodeMapping` for `barcode`, or increments the scan count
    /// on an existing mapping. Call this whenever the user saves an item that
    /// carries a barcode value.
    static func learnBarcode(
        _ barcode: String,
        productName: String,
        brand: String?,
        unit: String,
        category: Category?,
        price: Double?,
        context: ModelContext
    ) {
        if let existing = lookupMapping(for: barcode, context: context) {
            existing.recordScan()
        } else {
            let mapping = BarcodeMapping(
                barcode: barcode,
                productName: productName,
                brand: brand,
                defaultUnit: unit,
                category: category,
                averagePrice: price
            )
            context.insert(mapping)
        }
    }
}
