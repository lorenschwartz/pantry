//
//  ServicesMealPlanService.swift
//  pantry
//

import Foundation

struct MealPlanRequest {
    var startDate: Date
    var days: Int
    var mealTypes: [MealType]
    var maxPrepMinutes: Int?
    var dietaryTags: [String]
    var prioritizeExpiring: Bool
    var desiredServings: Int?

    init(
        startDate: Date,
        days: Int = 7,
        mealTypes: [MealType] = [.dinner],
        maxPrepMinutes: Int? = nil,
        dietaryTags: [String] = [],
        prioritizeExpiring: Bool = true,
        desiredServings: Int? = nil
    ) {
        self.startDate = startDate
        self.days = days
        self.mealTypes = mealTypes
        self.maxPrepMinutes = maxPrepMinutes
        self.dietaryTags = dietaryTags
        self.prioritizeExpiring = prioritizeExpiring
        self.desiredServings = desiredServings
    }
}

struct MealPlanDraftEntry {
    var date: Date
    var mealType: MealType
    var recipe: Recipe?
    var score: Double
    var confidence: Double
    var missingIngredients: [RecipeIngredient]
    var pantryCoverage: Double
    var rationale: String
    var servingsOverride: Int?
}

enum MealPlanService {
    static func generateDraft(
        request: MealPlanRequest,
        recipes: [Recipe],
        pantryItems: [PantryItem]
    ) -> [MealPlanDraftEntry] {
        let calendar = Calendar.current
        let expiring = pantryItems.filter { $0.isExpired || $0.isExpiringSoon }
        let filtered = recipes.filter { recipe in
            guard let maxPrep = request.maxPrepMinutes else { return true }
            return recipe.prepTime <= maxPrep
        }.filter { recipe in
            guard !request.dietaryTags.isEmpty else { return true }
            let tagNames = (recipe.tags ?? []).map { $0.name.lowercased() }
            return request.dietaryTags.allSatisfy { desired in
                tagNames.contains(desired.lowercased())
            }
        }

        typealias RankedRecipe = (
            recipe: Recipe,
            score: Double,
            pantryCoverage: Double,
            missingIngredients: [RecipeIngredient],
            expiringMatches: Int
        )

        var ranked: [RankedRecipe] = filtered.map { recipe in
            let result = RecipePantryService.checkRecipeMakeable(recipe: recipe, pantryItems: pantryItems)
            let pantryCoverage = result.matchPercentage / 100.0
            let expiringMatches = expiringMatchCount(recipe: recipe, expiringItems: expiring)
            let expiringScore = request.prioritizeExpiring ? min(1.0, Double(expiringMatches) / 2.0) : 0.0
            let score = (0.65 * pantryCoverage) + (0.35 * expiringScore)
            return (recipe, score, pantryCoverage, result.missingIngredients, expiringMatches)
        }.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.recipe.prepTime < rhs.recipe.prepTime
            }
            return lhs.score > rhs.score
        }

        if ranked.isEmpty {
            ranked = recipes.map { recipe in
                let result = RecipePantryService.checkRecipeMakeable(recipe: recipe, pantryItems: pantryItems)
                return (recipe, result.matchPercentage / 100.0, result.matchPercentage / 100.0, result.missingIngredients, 0)
            }.sorted { $0.1 > $1.1 }
        }

        var usedRecipeIDs = Set<UUID>()
        var entries: [MealPlanDraftEntry] = []

        for day in 0..<max(1, request.days) {
            guard let date = calendar.date(byAdding: .day, value: day, to: request.startDate) else { continue }
            for mealType in request.mealTypes {
                let candidate = ranked.first(where: { !usedRecipeIDs.contains($0.recipe.id) }) ?? ranked.first
                guard let selected = candidate else { continue }

                usedRecipeIDs.insert(selected.recipe.id)
                let rationale: String
                if selected.expiringMatches > 0 {
                    rationale = "Uses \(selected.expiringMatches) expiring pantry item(s)."
                } else if selected.pantryCoverage > 0 {
                    rationale = "High pantry coverage (\(Int(selected.pantryCoverage * 100))%)."
                } else {
                    rationale = "Best available match for current constraints."
                }

                entries.append(
                    MealPlanDraftEntry(
                        date: date,
                        mealType: mealType,
                        recipe: selected.recipe,
                        score: selected.score,
                        confidence: max(0.5, min(1.0, selected.score)),
                        missingIngredients: selected.missingIngredients,
                        pantryCoverage: selected.pantryCoverage,
                        rationale: rationale,
                        servingsOverride: request.desiredServings
                    )
                )
            }
        }

        return entries
    }

    static func aggregateMissingIngredients(from entries: [MealPlanDraftEntry]) -> [ShoppingListItem] {
        var merged: [String: (name: String, quantity: Double, unit: String)] = [:]

        for entry in entries {
            guard let recipe = entry.recipe else { continue }
            let baseServings = max(1, recipe.servings)
            let targetServings = entry.servingsOverride ?? recipe.servings
            let scaleFactor = Double(targetServings) / Double(baseServings)

            for ingredient in entry.missingIngredients where !ingredient.isOptional {
                let key = "\(ingredient.name.lowercased())::\(ingredient.unit.lowercased())"
                let scaled = ingredient.quantity * scaleFactor
                if let existing = merged[key] {
                    merged[key] = (existing.name, existing.quantity + scaled, existing.unit)
                } else {
                    merged[key] = (ingredient.name, scaled, ingredient.unit)
                }
            }
        }

        return merged.values
            .map { value in
                ShoppingListItem(name: value.name, quantity: value.quantity, unit: value.unit)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func expiringMatchCount(recipe: Recipe, expiringItems: [PantryItem]) -> Int {
        guard let ingredients = recipe.ingredients, !ingredients.isEmpty else { return 0 }
        var count = 0
        for ingredient in ingredients {
            let found = expiringItems.contains { item in
                item.name.localizedCaseInsensitiveContains(ingredient.name)
                || ingredient.name.localizedCaseInsensitiveContains(item.name)
            }
            if found { count += 1 }
        }
        return count
    }
}
