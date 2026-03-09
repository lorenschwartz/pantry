//
//  ViewsMealPlanMealPlanListView.swift
//  pantry
//

import SwiftUI
import SwiftData

struct MealPlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlan.startDate, order: .reverse) private var mealPlans: [MealPlan]

    var body: some View {
        List {
            if mealPlans.isEmpty {
                ContentUnavailableView(
                    "No Meal Plans",
                    systemImage: "calendar",
                    description: Text("Create your first AI-assisted weekly meal plan.")
                )
                Button("Create This Week") {
                    createCurrentWeekPlan()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(mealPlans) { plan in
                    NavigationLink {
                        MealPlanDetailView(mealPlan: plan)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                            Text(dateRangeText(plan))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\((plan.entries ?? []).count) entries")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deletePlans)
            }
        }
        .navigationTitle("Meal Plans")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createCurrentWeekPlan()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func createCurrentWeekPlan() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let plan = MealPlan(name: "This Week", startDate: start, endDate: end)
        modelContext.insert(plan)
        try? modelContext.save()
    }

    private func deletePlans(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(mealPlans[index])
        }
        try? modelContext.save()
    }

    private func dateRangeText(_ plan: MealPlan) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: plan.startDate)) - \(formatter.string(from: plan.endDate))"
    }
}

#Preview {
    NavigationStack {
        MealPlanListView()
    }
    .modelContainer(for: [
        MealPlan.self, MealPlanEntry.self, MealPlanEntryReason.self,
        MealPlanConstraintProfile.self, MealPlanGeneration.self, MealPlanFeedback.self,
        Recipe.self, RecipeIngredient.self, RecipeInstruction.self,
        RecipeCategory.self, RecipeTag.self, RecipeCookingNote.self, RecipeCollection.self,
        PantryItem.self, Category.self, StorageLocation.self,
        ShoppingListItem.self, Receipt.self, ReceiptItem.self, BarcodeMapping.self
    ], inMemory: true)
}

