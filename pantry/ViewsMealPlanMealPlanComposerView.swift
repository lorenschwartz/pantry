//
//  ViewsMealPlanMealPlanComposerView.swift
//  pantry
//

import SwiftUI

struct MealPlanComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(MealPlanSensitivitySettings.householdKey) private var householdSensitivityCSV = ""
    @AppStorage(MealPlanSensitivitySettings.guestKey) private var guestSensitivityCSV = ""
    @AppStorage(MealPlanSensitivitySettings.customTagsKey) private var customSensitivityTagsCSV = ""

    @State private var days = 7
    @State private var includeBreakfast = false
    @State private var includeLunch = false
    @State private var includeDinner = true
    @State private var includeSnack = false
    @State private var maxPrepEnabled = false
    @State private var maxPrepMinutes = 30
    @State private var prioritizeExpiring = true
    @State private var desiredServings = 2

    let onGenerate: (MealPlanRequest) -> Void

    private var householdSensitivities: [FoodSensitivity] {
        MealPlanSensitivitySettings.decodeSensitivityCSV(householdSensitivityCSV)
    }

    private var guestSensitivities: [FoodSensitivity] {
        MealPlanSensitivitySettings.decodeSensitivityCSV(guestSensitivityCSV)
    }

    private var customSensitivityTags: [String] {
        MealPlanSensitivitySettings.decodeCustomTags(customSensitivityTagsCSV)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    Stepper("Days: \(days)", value: $days, in: 1...14)
                    Stepper("Servings: \(desiredServings)", value: $desiredServings, in: 1...12)
                }

                Section("Meal Types") {
                    Toggle("Breakfast", isOn: $includeBreakfast)
                    Toggle("Lunch", isOn: $includeLunch)
                    Toggle("Dinner", isOn: $includeDinner)
                    Toggle("Snack", isOn: $includeSnack)
                }

                Section("Constraints") {
                    Toggle("Prioritize expiring items", isOn: $prioritizeExpiring)
                    Toggle("Limit prep time", isOn: $maxPrepEnabled)
                    if maxPrepEnabled {
                        Stepper("Max prep minutes: \(maxPrepMinutes)", value: $maxPrepMinutes, in: 5...90, step: 5)
                    }
                }
            }
            .navigationTitle("Generate My Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        let request = MealPlanRequest(
                            startDate: Date(),
                            days: days,
                            mealTypes: selectedMealTypes,
                            maxPrepMinutes: maxPrepEnabled ? maxPrepMinutes : nil,
                            householdSensitivities: householdSensitivities,
                            guestSensitivities: guestSensitivities,
                            customSensitivityTags: customSensitivityTags,
                            prioritizeExpiring: prioritizeExpiring,
                            desiredServings: desiredServings
                        )
                        onGenerate(request)
                        dismiss()
                    }
                    .disabled(selectedMealTypes.isEmpty)
                }
            }
        }
    }

    private var selectedMealTypes: [MealType] {
        var values: [MealType] = []
        if includeBreakfast { values.append(.breakfast) }
        if includeLunch { values.append(.lunch) }
        if includeDinner { values.append(.dinner) }
        if includeSnack { values.append(.snack) }
        return values
    }
}
