//
//  ServicesMealPlanAIProvider.swift
//  pantry
//

import Foundation

protocol MealPlanAIProvider {
    func generate(request: MealPlanRequest) async throws -> MealPlanAIResponse
}

struct MealPlanAIEntry: Codable {
    var dayOffset: Int
    var mealType: MealType
    var recipeName: String
    var confidence: Double
    var rationale: String
}

struct MealPlanAIResponse: Codable {
    var entries: [MealPlanAIEntry]

    static func decode(from json: String) throws -> MealPlanAIResponse {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(MealPlanAIResponse.self, from: data)
    }

    static func selectOrFallback(
        _ response: MealPlanAIResponse,
        fallback: [MealPlanAIEntry],
        minimumConfidence: Double = 0.6
    ) -> [MealPlanAIEntry] {
        guard !response.entries.isEmpty else { return fallback }
        let average = response.entries.map(\.confidence).reduce(0, +) / Double(response.entries.count)
        return average >= minimumConfidence ? response.entries : fallback
    }
}

struct DeterministicMealPlanAIProvider: MealPlanAIProvider {
    let recipes: [Recipe]
    let pantryItems: [PantryItem]

    func generate(request: MealPlanRequest) async throws -> MealPlanAIResponse {
        let draft = MealPlanService.generateDraft(
            request: request,
            recipes: recipes,
            pantryItems: pantryItems
        )

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: request.startDate)
        let entries = draft.compactMap { entry -> MealPlanAIEntry? in
            guard let recipe = entry.recipe else { return nil }
            let offset = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: entry.date)).day ?? 0
            return MealPlanAIEntry(
                dayOffset: offset,
                mealType: entry.mealType,
                recipeName: recipe.name,
                confidence: entry.confidence,
                rationale: entry.rationale
            )
        }

        return MealPlanAIResponse(entries: entries)
    }
}

