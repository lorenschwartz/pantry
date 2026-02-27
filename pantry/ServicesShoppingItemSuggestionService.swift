//
//  ShoppingItemSuggestionService.swift
//  pantry
//
//  Mines the app's on-device SwiftData history (pantry items and past shopping
//  list entries) to produce ranked, deduplicated form-fill suggestions.
//  No network or external AI is used.
//

import Foundation

// MARK: - Suggestion Model

/// A lightweight, non-persisted value type produced by `ShoppingItemSuggestionService`.
struct ShoppingSuggestion: Identifiable, Equatable {
    let id: UUID
    let name: String
    let quantity: Double
    let unit: String
    let estimatedPrice: Double?
    let category: Category?
    let source: Source

    enum Source: Equatable {
        case pantry
        case history
    }

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        estimatedPrice: Double? = nil,
        category: Category? = nil,
        source: Source
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.estimatedPrice = estimatedPrice
        self.category = category
        self.source = source
    }

    static func == (lhs: ShoppingSuggestion, rhs: ShoppingSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Service

/// Provides ranked form-fill suggestions for the shopping list add sheet.
///
/// All methods are pure functions that accept arrays, making them fully unit-testable
/// without a live SwiftData `ModelContext`.
class ShoppingItemSuggestionService {

    // MARK: - Search suggestions

    /// Returns up to `maxResults` suggestions whose name contains `query`
    /// (case-insensitive), drawn from pantry items first and shopping history second.
    ///
    /// Duplicates are suppressed (by lowercased name); pantry entries win when the
    /// same name appears in both sources.  Results are ranked: prefix matches before
    /// substring matches, then alphabetically.
    static func suggestions(
        for query: String,
        pantryItems: [PantryItem],
        shoppingHistory: [ShoppingListItem],
        maxResults: Int = 5
    ) -> [ShoppingSuggestion] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        let lower = q.lowercased()

        var seen = Set<String>()
        var results: [ShoppingSuggestion] = []

        // Pantry items first — carry real quantity, unit, price, and category
        for item in pantryItems where !item.isArchived {
            let nameLower = item.name.lowercased()
            guard nameLower.contains(lower), !seen.contains(nameLower) else { continue }
            seen.insert(nameLower)
            results.append(ShoppingSuggestion(
                name: item.name,
                quantity: max(1, item.quantity),
                unit: item.unit,
                estimatedPrice: item.price,
                category: item.category,
                source: .pantry
            ))
        }

        // Shopping history second — fills in items not in pantry
        for item in shoppingHistory {
            let nameLower = item.name.lowercased()
            guard nameLower.contains(lower), !seen.contains(nameLower) else { continue }
            seen.insert(nameLower)
            results.append(ShoppingSuggestion(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                estimatedPrice: item.estimatedPrice,
                category: item.category,
                source: .history
            ))
        }

        // Rank: prefix matches above substring matches, then alphabetical within each tier
        results.sort { a, b in
            let aPrefix = a.name.lowercased().hasPrefix(lower)
            let bPrefix = b.name.lowercased().hasPrefix(lower)
            if aPrefix != bPrefix { return aPrefix }
            return a.name.localizedCompare(b.name) == .orderedAscending
        }

        return Array(results.prefix(maxResults))
    }

    // MARK: - Recent items

    /// Returns up to `limit` unique recently-added shopping list items as suggestions,
    /// suitable for display as quick-tap chips when the name field is empty.
    ///
    /// `shoppingHistory` is expected to be sorted by `addedDate` descending
    /// (pass a `@Query(sort: \ShoppingListItem.addedDate, order: .reverse)` result).
    static func recentItems(
        from shoppingHistory: [ShoppingListItem],
        limit: Int = 5
    ) -> [ShoppingSuggestion] {
        var seen = Set<String>()
        var results: [ShoppingSuggestion] = []

        for item in shoppingHistory {
            let nameLower = item.name.lowercased()
            guard !seen.contains(nameLower) else { continue }
            seen.insert(nameLower)
            results.append(ShoppingSuggestion(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                estimatedPrice: item.estimatedPrice,
                category: item.category,
                source: .history
            ))
            if results.count == limit { break }
        }

        return results
    }
}
