//
//  ServicesMealPlanSensitivitySettings.swift
//  pantry
//

import Foundation

enum MealPlanSensitivitySettings {
    static let householdKey = "mealPlan.householdSensitivitiesCSV"
    static let guestKey = "mealPlan.guestSensitivitiesCSV"
    static let customTagsKey = "mealPlan.customSensitivityTagsCSV"

    static func decodeSensitivityCSV(_ raw: String) -> [FoodSensitivity] {
        let tokens = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        var result: [FoodSensitivity] = []
        var seen = Set<FoodSensitivity>()
        for token in tokens {
            guard let value = FoodSensitivity(rawValue: token), !seen.contains(value) else { continue }
            seen.insert(value)
            result.append(value)
        }
        return result
    }

    static func encodeSensitivityCSV(_ values: [FoodSensitivity]) -> String {
        var seen = Set<FoodSensitivity>()
        var ordered: [FoodSensitivity] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            ordered.append(value)
        }
        return ordered.map(\.rawValue).joined(separator: ",")
    }

    static func decodeCustomTags(_ raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",\n")
        let parts = raw.components(separatedBy: separators)

        var seen = Set<String>()
        var result: [String] = []
        for part in parts {
            let normalized = part.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            result.append(normalized)
        }
        return result
    }
}

extension FoodSensitivity {
    var displayName: String {
        switch self {
        case .treeNut:
            return "Tree Nut"
        default:
            return rawValue.capitalized
        }
    }
}
