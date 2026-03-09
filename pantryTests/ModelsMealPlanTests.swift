//
//  ModelsMealPlanTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

struct MealPlanModelTests {

    @Test func mealPlan_includesDateWithinRange() {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        let plan = MealPlan(name: "Week Plan", startDate: start, endDate: end)

        let mid = Calendar.current.date(byAdding: .day, value: 3, to: start)!
        #expect(plan.includes(mid))
    }

    @Test func mealPlan_excludesDateOutsideRange() {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        let plan = MealPlan(name: "Week Plan", startDate: start, endDate: end)

        let outside = Calendar.current.date(byAdding: .day, value: 8, to: start)!
        #expect(!plan.includes(outside))
    }

    @Test func mealPlanEntry_effectiveServings_usesOverrideWhenPresent() {
        let recipe = Recipe(name: "Pasta", servings: 4)
        let entry = MealPlanEntry(
            date: Date(),
            mealType: .dinner,
            status: .planned,
            servingsOverride: 2,
            recipe: recipe
        )

        #expect(entry.effectiveServings == 2)
    }

    @Test func mealPlanEntry_effectiveServings_fallsBackToRecipeServings() {
        let recipe = Recipe(name: "Pasta", servings: 4)
        let entry = MealPlanEntry(
            date: Date(),
            mealType: .dinner,
            status: .planned,
            recipe: recipe
        )

        #expect(entry.effectiveServings == 4)
    }

    @Test func mealPlanEntry_isHighConfidence_whenConfidenceAtOrAboveThreshold() {
        let entry = MealPlanEntry(
            date: Date(),
            mealType: .lunch,
            status: .planned,
            confidence: 0.8
        )

        #expect(entry.isHighConfidence)
    }
}

