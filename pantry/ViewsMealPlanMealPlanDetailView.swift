//
//  ViewsMealPlanMealPlanDetailView.swift
//  pantry
//

import SwiftUI
import SwiftData

struct MealPlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var mealPlan: MealPlan

    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]

    @State private var showingComposer = false

    var body: some View {
        List {
            if sortedEntries.isEmpty {
                ContentUnavailableView(
                    "No Meals Yet",
                    systemImage: "calendar.badge.plus",
                    description: Text("Generate a plan and the app will propose meals with pantry-aware rationale.")
                )
            } else {
                ForEach(sortedEntries, id: \.id) { entry in
                    MealPlanEntryCard(entry: entry)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Cooked") {
                                entry.status = .cooked
                            }
                            .tint(.green)

                            Button("Skip") {
                                entry.status = .skipped
                            }
                            .tint(.gray)
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(mealPlan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Generate My Week") {
                    showingComposer = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Shopping List") {
                    createShoppingList()
                }
                .disabled(sortedEntries.isEmpty)
            }
        }
        .sheet(isPresented: $showingComposer) {
            MealPlanComposerView { request in
                regenerate(using: request)
            }
        }
    }

    private var sortedEntries: [MealPlanEntry] {
        (mealPlan.entries ?? []).sorted {
            if Calendar.current.isDate($0.date, inSameDayAs: $1.date) {
                return mealTypeSortOrder($0.mealType) < mealTypeSortOrder($1.mealType)
            }
            return $0.date < $1.date
        }
    }

    private func mealTypeSortOrder(_ type: MealType) -> Int {
        switch type {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }

    private func regenerate(using request: MealPlanRequest) {
        for existing in mealPlan.entries ?? [] {
            modelContext.delete(existing)
        }
        mealPlan.entries = []

        let draft = MealPlanService.generateDraft(
            request: request,
            recipes: recipes,
            pantryItems: pantryItems
        )

        for (index, item) in draft.enumerated() {
            let entry = MealPlanEntry(
                date: item.date,
                mealType: item.mealType,
                status: .planned,
                servingsOverride: item.servingsOverride,
                position: index,
                confidence: item.confidence,
                recipe: item.recipe
            )
            let reason = MealPlanEntryReason(
                summary: item.rationale,
                pantryCoverage: item.pantryCoverage
            )
            reason.entry = entry
            entry.reason = reason
            entry.mealPlan = mealPlan
            modelContext.insert(reason)
            modelContext.insert(entry)
        }

        mealPlan.modifiedDate = Date()
        try? modelContext.save()
    }

    private func createShoppingList() {
        let draftEntries = sortedEntries.map { entry in
            MealPlanDraftEntry(
                date: entry.date,
                mealType: entry.mealType,
                recipe: entry.recipe,
                score: entry.confidence,
                confidence: entry.confidence,
                missingIngredients: entry.recipe.map {
                    RecipePantryService.checkRecipeMakeable(recipe: $0, pantryItems: pantryItems).missingIngredients
                } ?? [],
                pantryCoverage: entry.reason?.pantryCoverage ?? 0,
                rationale: entry.reason?.summary ?? "",
                servingsOverride: entry.servingsOverride
            )
        }

        let shoppingItems = MealPlanService.aggregateMissingIngredients(from: draftEntries)
        for item in shoppingItems {
            modelContext.insert(item)
        }
        try? modelContext.save()
    }
}

