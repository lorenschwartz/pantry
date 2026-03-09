//
//  ServicesMealPlanServiceTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

struct MealPlanServiceTests {

    @Test func generateDraft_prioritizesRecipesUsingExpiringItems() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let soon = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let milk = PantryItem(name: "Milk", quantity: 1, unit: "cup", expirationDate: soon)
        context.insert(milk)

        let smoothie = Recipe(name: "Smoothie", prepTime: 5, cookTime: 0, servings: 1)
        let smoothieMilk = RecipeIngredient(name: "Milk", quantity: 1, unit: "cup")
        context.insert(smoothie)
        context.insert(smoothieMilk)
        smoothieMilk.recipe = smoothie

        let toast = Recipe(name: "Toast", prepTime: 5, cookTime: 5, servings: 1)
        let toastBread = RecipeIngredient(name: "Bread", quantity: 2, unit: "slice")
        context.insert(toast)
        context.insert(toastBread)
        toastBread.recipe = toast

        let request = MealPlanRequest(
            startDate: Date(),
            days: 1,
            mealTypes: [.dinner],
            prioritizeExpiring: true
        )
        let entries = MealPlanService.generateDraft(
            request: request,
            recipes: [smoothie, toast],
            pantryItems: [milk]
        )

        #expect(entries.count == 1)
        #expect(entries.first?.recipe?.name == "Smoothie")
    }

    @Test func generateDraft_respectsMaxPrepMinutesConstraint() {
        let quick = Recipe(name: "Quick Salad", prepTime: 10, cookTime: 0, servings: 2)
        let slow = Recipe(name: "Slow Stew", prepTime: 35, cookTime: 45, servings: 4)

        let request = MealPlanRequest(
            startDate: Date(),
            days: 1,
            mealTypes: [.dinner],
            maxPrepMinutes: 20
        )

        let entries = MealPlanService.generateDraft(
            request: request,
            recipes: [slow, quick],
            pantryItems: []
        )

        #expect(entries.count == 1)
        #expect(entries.first?.recipe?.name == "Quick Salad")
    }

    @Test func aggregateMissingIngredients_mergesDuplicatesAndScalesServings() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let r1 = Recipe(name: "Pasta A", prepTime: 10, cookTime: 10, servings: 2)
        let r1Tomato = RecipeIngredient(name: "Tomato", quantity: 1, unit: "count")
        context.insert(r1)
        context.insert(r1Tomato)
        r1Tomato.recipe = r1

        let r2 = Recipe(name: "Pasta B", prepTime: 10, cookTime: 10, servings: 2)
        let r2Tomato = RecipeIngredient(name: "Tomato", quantity: 1, unit: "count")
        context.insert(r2)
        context.insert(r2Tomato)
        r2Tomato.recipe = r2

        let entries = [
            MealPlanDraftEntry(
                date: Date(),
                mealType: .dinner,
                recipe: r1,
                score: 1.0,
                confidence: 1.0,
                missingIngredients: [r1Tomato],
                pantryCoverage: 0,
                rationale: "test",
                servingsOverride: 4
            ),
            MealPlanDraftEntry(
                date: Date(),
                mealType: .lunch,
                recipe: r2,
                score: 1.0,
                confidence: 1.0,
                missingIngredients: [r2Tomato],
                pantryCoverage: 0,
                rationale: "test",
                servingsOverride: 2
            )
        ]

        let shopping = MealPlanService.aggregateMissingIngredients(from: entries)
        #expect(shopping.count == 1)
        #expect(shopping[0].name == "Tomato")
        #expect(shopping[0].quantity == 3)
    }
}

