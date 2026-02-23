//
//  PantryItem.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class PantryItem {
    var id: UUID
    var name: String
    var itemDescription: String?
    var quantity: Double
    var unit: String
    var brand: String?
    var price: Double?
    var purchaseDate: Date
    var expirationDate: Date?
    var barcode: String?
    var imageData: Data?
    var notes: String?
    var createdDate: Date
    var modifiedDate: Date
    var modifiedBy: String?
    var isArchived: Bool
    
    // Relationships
    var category: Category?
    var location: StorageLocation?
    var receiptItem: ReceiptItem?
    
    // Computed properties
    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }
    
    var isExpiringSoon: Bool {
        guard let expirationDate else { return false }
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return expirationDate <= sevenDaysFromNow && !isExpired
    }
    
    var daysUntilExpiration: Int? {
        guard let expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
    
    var isLowStock: Bool {
        // This will be compared against a threshold later
        return quantity <= 1
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        quantity: Double = 1,
        unit: String = "item",
        brand: String? = nil,
        price: Double? = nil,
        purchaseDate: Date = Date(),
        expirationDate: Date? = nil,
        barcode: String? = nil,
        imageData: Data? = nil,
        notes: String? = nil,
        category: Category? = nil,
        location: StorageLocation? = nil,
        modifiedBy: String? = nil
    ) {
        self.id = id
        self.name = name
        self.itemDescription = description
        self.quantity = quantity
        self.unit = unit
        self.brand = brand
        self.price = price
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.barcode = barcode
        self.imageData = imageData
        self.notes = notes
        self.category = category
        self.location = location
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.modifiedBy = modifiedBy
        self.isArchived = false
    }
}

// MARK: - Sample Data
extension PantryItem {
    static var sampleItems: [PantryItem] {
        [
            PantryItem(
                name: "Whole Milk",
                quantity: 1,
                unit: "gallon",
                brand: "Organic Valley",
                price: 5.99,
                expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
            ),
            PantryItem(
                name: "Sourdough Bread",
                quantity: 1,
                unit: "loaf",
                brand: "Boudin",
                price: 4.50,
                expirationDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
            ),
            PantryItem(
                name: "Eggs",
                quantity: 12,
                unit: "count",
                brand: "Vital Farms",
                price: 6.99,
                expirationDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())
            ),
            PantryItem(
                name: "Olive Oil",
                quantity: 1,
                unit: "bottle",
                brand: "Kirkland",
                price: 12.99,
                expirationDate: Calendar.current.date(byAdding: .month, value: 12, to: Date())
            ),
            PantryItem(
                name: "Cheddar Cheese",
                quantity: 0.5,
                unit: "lb",
                brand: "Tillamook",
                price: 7.99,
                expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
            )
        ]
    }
}
