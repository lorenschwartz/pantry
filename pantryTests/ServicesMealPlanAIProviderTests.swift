//
//  ServicesMealPlanAIProviderTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

struct MealPlanAIProviderTests {

    @Test func decodeResponse_parsesValidJSON() throws {
        let json = """
        {
          "entries": [
            {
              "dayOffset": 0,
              "mealType": "dinner",
              "recipeName": "Pasta",
              "confidence": 0.92,
              "rationale": "Uses expiring tomatoes"
            }
          ]
        }
        """

        let response = try MealPlanAIResponse.decode(from: json)
        #expect(response.entries.count == 1)
        #expect(response.entries[0].recipeName == "Pasta")
    }

    @Test func decodeResponse_throwsForInvalidJSON() {
        let invalid = "{ not-json }"
        #expect(throws: Error.self) {
            _ = try MealPlanAIResponse.decode(from: invalid)
        }
    }

    @Test func selectOrFallback_returnsFallbackWhenConfidenceTooLow() throws {
        let json = """
        {
          "entries": [
            {
              "dayOffset": 0,
              "mealType": "dinner",
              "recipeName": "Pasta",
              "confidence": 0.2,
              "rationale": "low confidence"
            }
          ]
        }
        """

        let response = try MealPlanAIResponse.decode(from: json)
        let fallback = [MealPlanAIEntry(dayOffset: 0, mealType: .dinner, recipeName: "Fallback", confidence: 1.0, rationale: "fallback")]
        let selected = MealPlanAIResponse.selectOrFallback(response, fallback: fallback, minimumConfidence: 0.6)

        #expect(selected.count == 1)
        #expect(selected[0].recipeName == "Fallback")
    }
}

