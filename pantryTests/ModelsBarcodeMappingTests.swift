//
//  ModelsBarcodeMappingTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

struct BarcodeMappingTests {

    // MARK: - Initial State

    @Test func init_setsTimesScannedToOne() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "012345678901", productName: "Whole Milk")
        context.insert(mapping)
        #expect(mapping.timesScanned == 1)
    }

    // MARK: - recordScan

    @Test func recordScan_incrementsTimesScanned() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "012345678901", productName: "Whole Milk")
        context.insert(mapping)

        mapping.recordScan()

        #expect(mapping.timesScanned == 2)
    }

    @Test func recordScan_updatesLastScannedDate() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "012345678902", productName: "Orange Juice")
        context.insert(mapping)

        let beforeScan = Date()
        mapping.recordScan()

        #expect(mapping.lastScannedDate >= beforeScan)
    }

    @Test func recordScan_accumulatesCorrectlyAcrossMultipleCalls() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(barcode: "012345678903", productName: "Butter")
        context.insert(mapping)

        mapping.recordScan()
        mapping.recordScan()
        mapping.recordScan()

        #expect(mapping.timesScanned == 4) // starts at 1 + 3 calls
    }

    // MARK: - Context persistence

    @Test func barcodeMapping_canBeFetchedByBarcode() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let mapping = BarcodeMapping(
            barcode: "099482448706",
            productName: "Kirkland Olive Oil",
            brand: "Kirkland",
            defaultUnit: "bottle",
            averagePrice: 12.99
        )
        context.insert(mapping)

        let descriptor = FetchDescriptor<BarcodeMapping>(
            predicate: #Predicate { $0.barcode == "099482448706" }
        )
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results[0].productName == "Kirkland Olive Oil")
        #expect(results[0].brand == "Kirkland")
        #expect(results[0].averagePrice == 12.99)
    }

    @Test func barcodeMapping_returnsEmptyWhenBarcodeNotFound() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<BarcodeMapping>(
            predicate: #Predicate { $0.barcode == "000000000000" }
        )
        let results = try context.fetch(descriptor)

        #expect(results.isEmpty)
    }
}
