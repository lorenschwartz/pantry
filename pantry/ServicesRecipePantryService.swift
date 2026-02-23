//
//  RecipePantryService.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData

/// Service for managing recipe and pantry integration
class RecipePantryService {
    
    // MARK: - Recipe Matching
    
    /// Check which recipes can be made with current inventory
    static func makeableRecipes(
        recipes: [Recipe],
        pantryItems: [PantryItem]
    ) -> [(recipe: Recipe, matchPercentage: Double, missingIngredients: [RecipeIngredient])] {
        
        recipes.map { recipe in
            let result = checkRecipeMakeable(recipe: recipe, pantryItems: pantryItems)
            return (recipe, result.matchPercentage, result.missingIngredients)
        }
    }
    
    /// Check if a specific recipe can be made with current inventory
    static func checkRecipeMakeable(
        recipe: Recipe,
        pantryItems: [PantryItem]
    ) -> (matchPercentage: Double, missingIngredients: [RecipeIngredient], availableIngredients: [RecipeIngredient]) {
        
        guard let ingredients = recipe.ingredients, !ingredients.isEmpty else {
            return (100.0, [], [])
        }
        
        var available: [RecipeIngredient] = []
        var missing: [RecipeIngredient] = []
        
        for ingredient in ingredients {
            if isIngredientAvailable(ingredient: ingredient, pantryItems: pantryItems) {
                available.append(ingredient)
            } else {
                missing.append(ingredient)
            }
        }
        
        let matchPercentage = (Double(available.count) / Double(ingredients.count)) * 100
        
        return (matchPercentage, missing, available)
    }
    
    /// Check if a specific ingredient is available in pantry
    static func isIngredientAvailable(
        ingredient: RecipeIngredient,
        pantryItems: [PantryItem]
    ) -> Bool {
        // Try exact name match first
        if let _ = pantryItems.first(where: { 
            $0.name.localizedCaseInsensitiveCompare(ingredient.name) == .orderedSame &&
            $0.quantity > 0
        }) {
            return true
        }
        
        // Try fuzzy match (contains)
        if let _ = pantryItems.first(where: { 
            $0.name.localizedCaseInsensitiveContains(ingredient.name) &&
            $0.quantity > 0
        }) {
            return true
        }
        
        // Try reverse match (ingredient name contains pantry item name)
        if let _ = pantryItems.first(where: { 
            ingredient.name.localizedCaseInsensitiveContains($0.name) &&
            $0.quantity > 0
        }) {
            return true
        }
        
        return false
    }
    
    // MARK: - Pantry Deduction
    
    /// Deduct recipe ingredients from pantry when cooking
    static func deductIngredientsFromPantry(
        recipe: Recipe,
        pantryItems: [PantryItem],
        scaleFactor: Double = 1.0,
        modelContext: ModelContext
    ) -> [PantryItem] {
        
        guard let ingredients = recipe.ingredients else { return [] }
        
        var updatedItems: [PantryItem] = []
        
        for ingredient in ingredients {
            // Find matching pantry item
            if let pantryItem = findMatchingPantryItem(
                for: ingredient,
                in: pantryItems
            ) {
                // Calculate scaled quantity
                let quantityToDeduct = ingredient.quantity * scaleFactor
                
                // Deduct from pantry (convert units if needed)
                let convertedQuantity = convertQuantity(
                    from: ingredient.unit,
                    to: pantryItem.unit,
                    quantity: quantityToDeduct
                )
                
                pantryItem.quantity = max(0, pantryItem.quantity - convertedQuantity)
                pantryItem.modifiedDate = Date()
                
                updatedItems.append(pantryItem)
            }
        }
        
        return updatedItems
    }
    
    /// Find matching pantry item for recipe ingredient
    static func findMatchingPantryItem(
        for ingredient: RecipeIngredient,
        in pantryItems: [PantryItem]
    ) -> PantryItem? {
        // Try exact match first
        if let item = pantryItems.first(where: { 
            $0.name.localizedCaseInsensitiveCompare(ingredient.name) == .orderedSame 
        }) {
            return item
        }
        
        // Try fuzzy match
        if let item = pantryItems.first(where: { 
            $0.name.localizedCaseInsensitiveContains(ingredient.name) ||
            ingredient.name.localizedCaseInsensitiveContains($0.name)
        }) {
            return item
        }
        
        return nil
    }
    
    // MARK: - Shopping List Generation
    
    /// Generate shopping list items for missing ingredients
    static func generateShoppingList(
        recipe: Recipe,
        pantryItems: [PantryItem],
        scaleFactor: Double = 1.0
    ) -> [ShoppingListItem] {
        
        let result = checkRecipeMakeable(recipe: recipe, pantryItems: pantryItems)
        
        return result.missingIngredients.map { ingredient in
            ShoppingListItem(
                name: ingredient.name,
                quantity: ingredient.quantity * scaleFactor,
                unit: ingredient.unit,
                notes: ingredient.notes,
                priority: 1,
                relatedPantryItemID: nil
            )
        }
    }
    
    // MARK: - Recipe Suggestions
    
    /// Suggest recipes based on expiring items
    static func suggestRecipesForExpiringItems(
        recipes: [Recipe],
        expiringItems: [PantryItem]
    ) -> [(recipe: Recipe, expiringIngredientsUsed: [PantryItem])] {
        
        var suggestions: [(recipe: Recipe, expiringIngredientsUsed: [PantryItem])] = []
        
        for recipe in recipes {
            guard let ingredients = recipe.ingredients else { continue }
            
            var expiringIngredientsUsed: [PantryItem] = []
            
            for ingredient in ingredients {
                if let expiringItem = expiringItems.first(where: { pantryItem in
                    pantryItem.name.localizedCaseInsensitiveContains(ingredient.name) ||
                    ingredient.name.localizedCaseInsensitiveContains(pantryItem.name)
                }) {
                    expiringIngredientsUsed.append(expiringItem)
                }
            }
            
            if !expiringIngredientsUsed.isEmpty {
                suggestions.append((recipe, expiringIngredientsUsed))
            }
        }
        
        // Sort by number of expiring ingredients used (most to least)
        return suggestions.sorted { $0.expiringIngredientsUsed.count > $1.expiringIngredientsUsed.count }
    }
    
    // MARK: - Unit Conversion
    
    /// Simple unit conversion (can be expanded for more accuracy)
    static func convertQuantity(from: String, to: String, quantity: Double) -> Double {
        // If units match, no conversion needed
        if from.lowercased() == to.lowercased() {
            return quantity
        }
        
        // Handle common conversions
        let fromUnit = from.lowercased()
        let toUnit = to.lowercased()
        
        // Volume conversions (approximate)
        let volumeConversions: [String: Double] = [
            "cup": 240,      // mL
            "tbsp": 15,      // mL
            "tsp": 5,        // mL
            "ml": 1,
            "l": 1000,
            "oz": 29.5735,   // mL (fluid ounce)
            "gallon": 3785,  // mL
            "quart": 946,    // mL
            "pint": 473      // mL
        ]
        
        // Weight conversions (approximate)
        let weightConversions: [String: Double] = [
            "g": 1,
            "kg": 1000,
            "lb": 453.592,   // grams
            "oz": 28.3495    // grams (weight ounce)
        ]
        
        // Try volume conversion
        if let fromValue = volumeConversions[fromUnit],
           let toValue = volumeConversions[toUnit] {
            return quantity * (fromValue / toValue)
        }
        
        // Try weight conversion
        if let fromValue = weightConversions[fromUnit],
           let toValue = weightConversions[toUnit] {
            return quantity * (fromValue / toValue)
        }
        
        // If no conversion available, return original quantity
        return quantity
    }
    
    // MARK: - Ingredient Substitution
    
    /// Common ingredient substitutions
    static let commonSubstitutions: [String: [String]] = [
        "butter": ["margarine", "oil", "coconut oil"],
        "milk": ["almond milk", "soy milk", "oat milk", "coconut milk"],
        "egg": ["flax egg", "chia egg", "applesauce"],
        "sugar": ["honey", "maple syrup", "agave", "stevia"],
        "flour": ["almond flour", "coconut flour", "whole wheat flour"],
        "cream": ["half and half", "evaporated milk", "coconut cream"],
        "sour cream": ["greek yogurt", "plain yogurt"],
        "chicken stock": ["vegetable stock", "beef stock", "chicken broth"],
        "olive oil": ["vegetable oil", "canola oil", "avocado oil"]
    ]
    
    /// Find possible substitutions for a missing ingredient
    static func findSubstitutions(
        for ingredient: RecipeIngredient,
        in pantryItems: [PantryItem]
    ) -> [PantryItem] {
        
        let ingredientLower = ingredient.name.lowercased()
        
        // Check if we have substitution suggestions
        for (key, substitutes) in commonSubstitutions {
            if ingredientLower.contains(key) {
                // Look for these substitutes in pantry
                return pantryItems.filter { item in
                    substitutes.contains { substitute in
                        item.name.lowercased().contains(substitute)
                    }
                }
            }
        }
        
        return []
    }
}
