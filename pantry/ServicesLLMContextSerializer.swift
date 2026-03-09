//
//  ServicesLLMContextSerializer.swift
//  pantry
//
//  Intent-scoped, least-privilege serialization for LLM tool outputs.
//

import Foundation

enum LLMContextSerializer {

    static func pantryItemsSummaryJSON(
        _ items: [PantryItem],
        includeSensitiveNotes: Bool = false,
        maxItems: Int = 100
    ) -> String {
        guard !items.isEmpty else { return "[]" }
        let dicts: [[String: Any]] = items.prefix(maxItems).map { item in
            var d: [String: Any] = [
                "name": item.name,
                "quantity": item.quantity,
                "unit": item.unit,
                "is_expired": item.isExpired,
                "is_expiring_soon": item.isExpiringSoon,
                "low_stock": item.isLowStock
            ]
            if let days = item.daysUntilExpiration { d["days_until_expiration"] = days }
            if let cat = item.category { d["category"] = cat.name }
            if let loc = item.location { d["location"] = loc.name }
            if let brand = item.brand { d["brand"] = brand }

            // Sensitive/freeform fields are opt-in for explicit detail requests.
            if includeSensitiveNotes, let notes = item.notes { d["notes"] = notes }
            if includeSensitiveNotes, let price = item.price { d["price"] = price }
            return d
        }
        return serialize(dicts)
    }

    static func recipesSummaryJSON(
        _ recipes: [Recipe],
        maxItems: Int = 100
    ) -> String {
        guard !recipes.isEmpty else { return "[]" }
        let dicts: [[String: Any]] = recipes.prefix(maxItems).map { recipe in
            var d: [String: Any] = [
                "name": recipe.name,
                "prep_time_minutes": recipe.prepTime,
                "cook_time_minutes": recipe.cookTime,
                "total_time_minutes": recipe.totalTime,
                "servings": recipe.servings,
                "difficulty": recipe.difficulty.rawValue,
                "ingredient_count": recipe.ingredientCount,
                "is_favorite": recipe.isFavorite
            ]
            if let rating = recipe.rating { d["rating"] = rating }
            return d
        }
        return serialize(dicts)
    }

    static func shoppingItemsSummaryJSON(
        _ items: [ShoppingListItem],
        includeSensitiveNotes: Bool = false,
        maxItems: Int = 100
    ) -> String {
        guard !items.isEmpty else { return "[]" }
        let dicts: [[String: Any]] = items.prefix(maxItems).map { item in
            var d: [String: Any] = [
                "name": item.name,
                "quantity": item.quantity,
                "unit": item.unit,
                "is_checked": item.isChecked,
                "priority": item.priority
            ]
            if let cat = item.category { d["category"] = cat.name }
            if includeSensitiveNotes, let notes = item.notes { d["notes"] = notes }
            if includeSensitiveNotes, let price = item.estimatedPrice { d["estimated_price"] = price }
            return d
        }
        return serialize(dicts)
    }

    static func expiringItemsSummaryJSON(
        _ items: [PantryItem],
        maxItems: Int = 100
    ) -> String {
        let expiring = items.filter { $0.isExpiringSoon || $0.isExpired }
        guard !expiring.isEmpty else { return "[]" }
        let dicts: [[String: Any]] = expiring.prefix(maxItems).map { item in
            var d: [String: Any] = [
                "name": item.name,
                "quantity": item.quantity,
                "unit": item.unit,
                "is_expired": item.isExpired
            ]
            if let days = item.daysUntilExpiration { d["days_until_expiration"] = days }
            if let cat = item.category { d["category"] = cat.name }
            return d
        }
        return serialize(dicts)
    }

    private static func serialize(_ object: Any) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        ), let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}

