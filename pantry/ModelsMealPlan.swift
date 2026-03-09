//
//  ModelsMealPlan.swift
//  pantry
//

import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

enum MealPlanEntryStatus: String, Codable {
    case planned
    case cooked
    case skipped
}

enum MealPlanFeedbackAction: String, Codable {
    case accepted
    case swapped
    case rejected
}

@Model
final class MealPlan {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var createdDate: Date
    var modifiedDate: Date
    var isActive: Bool

    var entries: [MealPlanEntry]?

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.isActive = isActive
    }

    func includes(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return day >= start && day <= end
    }
}

@Model
final class MealPlanEntry {
    var id: UUID
    var date: Date
    var mealType: MealType
    var status: MealPlanEntryStatus
    var servingsOverride: Int?
    var position: Int
    var confidence: Double
    var isUserPinned: Bool

    var mealPlan: MealPlan?

    var recipe: Recipe?

    var reason: MealPlanEntryReason?

    var feedback: [MealPlanFeedback]?

    init(
        id: UUID = UUID(),
        date: Date,
        mealType: MealType,
        status: MealPlanEntryStatus = .planned,
        servingsOverride: Int? = nil,
        position: Int = 0,
        confidence: Double = 1.0,
        isUserPinned: Bool = false,
        recipe: Recipe? = nil
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.status = status
        self.servingsOverride = servingsOverride
        self.position = position
        self.confidence = confidence
        self.isUserPinned = isUserPinned
        self.recipe = recipe
    }

    var effectiveServings: Int {
        servingsOverride ?? recipe?.servings ?? 1
    }

    var isHighConfidence: Bool {
        confidence >= 0.8
    }
}

@Model
final class MealPlanConstraintProfile {
    var id: UUID
    var maxPrepMinutes: Int?
    var budgetTarget: Double?
    var householdSize: Int
    var dietaryTagsCSV: String
    var preferredCuisinesCSV: String
    var avoidIngredientsCSV: String

    var mealPlan: MealPlan?

    init(
        id: UUID = UUID(),
        maxPrepMinutes: Int? = nil,
        budgetTarget: Double? = nil,
        householdSize: Int = 1,
        dietaryTagsCSV: String = "",
        preferredCuisinesCSV: String = "",
        avoidIngredientsCSV: String = ""
    ) {
        self.id = id
        self.maxPrepMinutes = maxPrepMinutes
        self.budgetTarget = budgetTarget
        self.householdSize = householdSize
        self.dietaryTagsCSV = dietaryTagsCSV
        self.preferredCuisinesCSV = preferredCuisinesCSV
        self.avoidIngredientsCSV = avoidIngredientsCSV
    }
}

@Model
final class MealPlanGeneration {
    var id: UUID
    var createdDate: Date
    var strategyVersion: String
    var inputSnapshotJSON: String
    var modelID: String
    var overallConfidence: Double

    var mealPlan: MealPlan?

    init(
        id: UUID = UUID(),
        strategyVersion: String = "v1",
        inputSnapshotJSON: String = "{}",
        modelID: String = "deterministic-v1",
        overallConfidence: Double = 1.0
    ) {
        self.id = id
        self.createdDate = Date()
        self.strategyVersion = strategyVersion
        self.inputSnapshotJSON = inputSnapshotJSON
        self.modelID = modelID
        self.overallConfidence = overallConfidence
    }
}

@Model
final class MealPlanEntryReason {
    var id: UUID
    var summary: String
    var pantryCoverage: Double
    var expiringItemsCSV: String
    var estimatedCost: Double?

    var entry: MealPlanEntry?

    init(
        id: UUID = UUID(),
        summary: String,
        pantryCoverage: Double,
        expiringItemsCSV: String = "",
        estimatedCost: Double? = nil
    ) {
        self.id = id
        self.summary = summary
        self.pantryCoverage = pantryCoverage
        self.expiringItemsCSV = expiringItemsCSV
        self.estimatedCost = estimatedCost
    }
}

@Model
final class MealPlanFeedback {
    var id: UUID
    var action: MealPlanFeedbackAction
    var reasonCode: String?
    var freeformNote: String?
    var createdDate: Date

    var entry: MealPlanEntry?

    init(
        id: UUID = UUID(),
        action: MealPlanFeedbackAction,
        reasonCode: String? = nil,
        freeformNote: String? = nil
    ) {
        self.id = id
        self.action = action
        self.reasonCode = reasonCode
        self.freeformNote = freeformNote
        self.createdDate = Date()
    }
}
