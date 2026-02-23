//
//  BarcodeMapping.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData

@Model
final class BarcodeMapping {
    var barcode: String
    var productName: String
    var brand: String?
    var defaultUnit: String
    var category: Category?
    var averagePrice: Double?
    var timesScanned: Int
    var lastScannedDate: Date
    var createdDate: Date
    
    init(
        barcode: String,
        productName: String,
        brand: String? = nil,
        defaultUnit: String = "item",
        category: Category? = nil,
        averagePrice: Double? = nil
    ) {
        self.barcode = barcode
        self.productName = productName
        self.brand = brand
        self.defaultUnit = defaultUnit
        self.category = category
        self.averagePrice = averagePrice
        self.timesScanned = 1
        self.lastScannedDate = Date()
        self.createdDate = Date()
    }
    
    func recordScan() {
        timesScanned += 1
        lastScannedDate = Date()
    }
}
