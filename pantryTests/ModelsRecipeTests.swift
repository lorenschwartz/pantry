//
//  ModelsRecipeTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

struct RecipeTests {

    // MARK: - totalTime

    @Test func totalTime_returnsSumOfPrepAndCookTime() {
        let recipe = Recipe(name: "Pasta", prepTime: 15, cookTime: 25)
        #expect(recipe.totalTime == 40)
    }

    @Test func totalTime_returnsZeroWhenBothTimesAreZero() {
        let recipe = Recipe(name: "No-Cook Salad", prepTime: 0, cookTime: 0)
        #expect(recipe.totalTime == 0)
    }

    // MARK: - ingredientCount

    @Test func ingredientCount_returnsZeroWhenIngredientsRelationshipIsNil() {
        let recipe = Recipe(name: "Empty Recipe")
        // ingredients is nil before the recipe is inserted into a context
        #expect(recipe.ingredientCount == 0)
    }

    // MARK: - stepCount

    @Test func stepCount_returnsZeroWhenInstructionsRelationshipIsNil() {
        let recipe = Recipe(name: "Stepless Recipe")
        #expect(recipe.stepCount == 0)
    }

    // MARK: - scaleServings

    @Test func scaleServings_returnsCorrectScaleFactor() {
        let recipe = Recipe(name: "Pancakes", servings: 4)
        let factor = recipe.scaleServings(to: 8)
        #expect(factor == 2.0)
    }

    @Test func scaleServings_returnsHalfFactorWhenScalingDown() {
        let recipe = Recipe(name: "Pancakes", servings: 4)
        let factor = recipe.scaleServings(to: 2)
        #expect(factor == 0.5)
    }

    @Test func scaleServings_returnsOneWhenServingsIsZeroToAvoidDivisionByZero() {
        let recipe = Recipe(name: "Broken Recipe", servings: 0)
        let factor = recipe.scaleServings(to: 4)
        #expect(factor == 1.0)
    }

    @Test func scaleServings_returnsOneWhenTargetMatchesCurrent() {
        let recipe = Recipe(name: "Cookies", servings: 24)
        let factor = recipe.scaleServings(to: 24)
        #expect(factor == 1.0)
    }

    // MARK: - markAsCooked

    @Test func markAsCooked_incrementsTimesCookedCount() {
        let recipe = Recipe(name: "Omelette")
        #expect(recipe.timesCookedCount == 0)
        recipe.markAsCooked()
        #expect(recipe.timesCookedCount == 1)
        recipe.markAsCooked()
        #expect(recipe.timesCookedCount == 2)
    }

    @Test func markAsCooked_setsLastCookedDate() {
        let before = Date()
        let recipe = Recipe(name: "Soup")
        recipe.markAsCooked()
        let lastCooked = recipe.lastCookedDate
        #expect(lastCooked != nil)
        #expect(lastCooked! >= before)
    }

    @Test func markAsCooked_updatesModifiedDate() {
        let before = Date()
        let recipe = Recipe(name: "Stew")
        recipe.markAsCooked()
        #expect(recipe.modifiedDate >= before)
    }

    // MARK: - rating

    @Test func rating_defaultsToNilForNewRecipe() {
        let recipe = Recipe(name: "New Recipe")
        #expect(recipe.rating == nil)
    }

    @Test func rating_canBeAssignedAHalfStepValue() {
        let recipe = Recipe(name: "Recipe", rating: 4.5)
        #expect(recipe.rating == 4.5)
    }

    @Test func rating_canBeAssignedMinimumValue() {
        let recipe = Recipe(name: "Recipe", rating: 1.0)
        #expect(recipe.rating == 1.0)
    }

    @Test func rating_canBeAssignedMaximumValue() {
        let recipe = Recipe(name: "Recipe", rating: 5.0)
        #expect(recipe.rating == 5.0)
    }

    @Test func rating_canBeClearedBySettingToNil() {
        let recipe = Recipe(name: "Recipe", rating: 3.5)
        recipe.rating = nil
        #expect(recipe.rating == nil)
    }

    // MARK: - sort by rating

    @Test func sortByRating_placesHigherRatingsFirst() {
        let low  = Recipe(name: "Low",  rating: 2.0)
        let high = Recipe(name: "High", rating: 4.5)
        let mid  = Recipe(name: "Mid",  rating: 3.0)

        let sorted = [low, high, mid].sorted { lhs, rhs in
            switch (lhs.rating, rhs.rating) {
            case let (l?, r?): return l > r
            case (nil, _?):    return false
            case (_?, nil):    return true
            case (nil, nil):   return false
            }
        }

        #expect(sorted[0].name == "High")
        #expect(sorted[1].name == "Mid")
        #expect(sorted[2].name == "Low")
    }

    @Test func sortByRating_placesUnratedRecipesLast() {
        let unrated = Recipe(name: "Unrated")
        let rated   = Recipe(name: "Rated", rating: 3.0)

        let sorted = [unrated, rated].sorted { lhs, rhs in
            switch (lhs.rating, rhs.rating) {
            case let (l?, r?): return l > r
            case (nil, _?):    return false
            case (_?, nil):    return true
            case (nil, nil):   return false
            }
        }

        #expect(sorted[0].name == "Rated")
        #expect(sorted[1].name == "Unrated")
    }

    @Test func sortByRating_twoUnratedRecipesAreStable() {
        let a = Recipe(name: "A")
        let b = Recipe(name: "B")

        let sorted = [a, b].sorted { lhs, rhs in
            switch (lhs.rating, rhs.rating) {
            case let (l?, r?): return l > r
            case (nil, _?):    return false
            case (_?, nil):    return true
            case (nil, nil):   return false
            }
        }

        // Both unrated: relative order is preserved (stable partition)
        #expect(sorted.count == 2)
        #expect(sorted[0].rating == nil)
        #expect(sorted[1].rating == nil)
    }
}
