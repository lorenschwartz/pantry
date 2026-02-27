//
//  LowStockService.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import Foundation
import SwiftData

/// Service for detecting low-stock pantry items and auto-generating shopping list entries.
class LowStockService {

    /// Quantity at or below which an item is considered low stock.
    static let defaultThreshold: Double = 1.0

    // MARK: - Detection

    /// Returns non-expired, non-archived pantry items whose quantity is at or below `threshold`.
    static func detectLowStockItems(
        from pantryItems: [PantryItem],
        threshold: Double = defaultThreshold
    ) -> [PantryItem] {
        pantryItems.filter { $0.quantity <= threshold && !$0.isExpired && !$0.isArchived }
    }

    // MARK: - Deduplication

    /// Returns `true` if the shopping list already contains an item with the same name
    /// as `pantryItem` (case-insensitive comparison).
    static func isAlreadyOnList(
        _ pantryItem: PantryItem,
        existingItems: [ShoppingListItem]
    ) -> Bool {
        existingItems.contains {
            $0.name.localizedCaseInsensitiveCompare(pantryItem.name) == .orderedSame
        }
    }

    // MARK: - Auto-add

    /// Creates `ShoppingListItem` entries for each low-stock item that is not already on
    /// the shopping list.  Inserts them into `context` and returns the newly added items.
    ///
    /// - Items with zero quantity receive high priority (2); others receive medium priority (1).
    /// - Each new item is linked to its source pantry item via `relatedPantryItemID`.
    @discardableResult
    static func addToShoppingList(
        _ lowStockItems: [PantryItem],
        existingList: [ShoppingListItem],
        context: ModelContext
    ) -> [ShoppingListItem] {
        var added: [ShoppingListItem] = []

        for pantryItem in lowStockItems {
            guard !isAlreadyOnList(pantryItem, existingItems: existingList) else { continue }

            let priority: Int = pantryItem.quantity == 0 ? 2 : 1
            let listItem = ShoppingListItem(
                name: pantryItem.name,
                quantity: 1,
                unit: pantryItem.unit,
                estimatedPrice: pantryItem.price,
                priority: priority,
                category: pantryItem.category,
                relatedPantryItemID: pantryItem.id
            )
            context.insert(listItem)
            added.append(listItem)
        }

        return added
    }
}
