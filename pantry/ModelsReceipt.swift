//
//  Receipt.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData

@Model
final class Receipt {
    var id: UUID
    var storeName: String?
    var purchaseDate: Date
    var totalAmount: Double?
    var imageData: Data?
    var rawOCRText: String?
    var createdDate: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var items: [ReceiptItem]?
    
    var itemCount: Int {
        items?.count ?? 0
    }
    
    init(
        id: UUID = UUID(),
        storeName: String? = nil,
        purchaseDate: Date = Date(),
        totalAmount: Double? = nil,
        imageData: Data? = nil,
        rawOCRText: String? = nil
    ) {
        self.id = id
        self.storeName = storeName
        self.purchaseDate = purchaseDate
        self.totalAmount = totalAmount
        self.imageData = imageData
        self.rawOCRText = rawOCRText
        self.createdDate = Date()
    }
}

@Model
final class ReceiptItem {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var price: Double?
    var isAddedToPantry: Bool
    
    // Relationships
    var receipt: Receipt?
    var pantryItem: PantryItem?
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: String = "item",
        price: Double? = nil,
        isAddedToPantry: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.price = price
        self.isAddedToPantry = isAddedToPantry
    }
}

// MARK: - Sample Data
extension Receipt {
    static var sampleReceipt: Receipt {
        let receipt = Receipt(
            storeName: "Whole Foods",
            purchaseDate: Date(),
            totalAmount: 45.32
        )
        return receipt
    }
}
