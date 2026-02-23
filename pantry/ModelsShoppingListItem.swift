//
//  ShoppingListItem.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData

@Model
final class ShoppingListItem {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var notes: String?
    var isChecked: Bool
    var addedDate: Date
    var checkedDate: Date?
    var estimatedPrice: Double?
    var priority: Int // 0 = low, 1 = medium, 2 = high
    var addedBy: String?
    
    // Optional relationship to pantry item (if auto-generated from low stock)
    var relatedPantryItemID: UUID?
    
    // Optional relationship to category
    var category: Category?
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: String = "item",
        notes: String? = nil,
        isChecked: Bool = false,
        estimatedPrice: Double? = nil,
        priority: Int = 1,
        addedBy: String? = nil,
        category: Category? = nil,
        relatedPantryItemID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.isChecked = isChecked
        self.addedDate = Date()
        self.estimatedPrice = estimatedPrice
        self.priority = priority
        self.addedBy = addedBy
        self.category = category
        self.relatedPantryItemID = relatedPantryItemID
    }
}

// MARK: - Sample Data
extension ShoppingListItem {
    static var sampleItems: [ShoppingListItem] {
        [
            ShoppingListItem(name: "Milk", quantity: 1, unit: "gallon", priority: 2),
            ShoppingListItem(name: "Bread", quantity: 2, unit: "loaves", priority: 1),
            ShoppingListItem(name: "Bananas", quantity: 6, unit: "count", priority: 1),
            ShoppingListItem(name: "Coffee", quantity: 1, unit: "bag", notes: "Medium roast", priority: 2),
            ShoppingListItem(name: "Butter", quantity: 1, unit: "lb", priority: 0, isChecked: true)
        ]
    }
}
