//
//  MainTabView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddItem = false
    @State private var showAddRecipe = false
    @State private var showAddShoppingItem = false
    @State private var showAddReceipt = false
    @State private var showMoreMenu = false

    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                DashboardView()
            case 1:
                PantryListView(showAddItem: $showAddItem)
                    .withGearIcon(showMoreMenu: $showMoreMenu)
            case 2:
                ShoppingListView(showAddItem: $showAddShoppingItem)
                    .withGearIcon(showMoreMenu: $showMoreMenu)
            case 3:
                ReceiptsListView(showingSourcePicker: $showAddReceipt)
                    .withGearIcon(showMoreMenu: $showMoreMenu)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(
                selectedTab: $selectedTab,
                onAddTapped: handleAddButtonTap
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showMoreMenu) {
            MoreMenuView()
        }
    }

    private func handleAddButtonTap() {
        switch selectedTab {
        case 1:
            showAddItem = true
        case 2:
            showAddShoppingItem = true
        case 3:
            showAddReceipt = true
        default:
            showAddItem = true
            break
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house", label: "Home", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabBarButton(icon: "cabinet", label: "Pantry", isSelected: selectedTab == 1) {
                selectedTab = 1
            }

            Button(action: onAddTapped) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.16), radius: 6, x: 0, y: 2)

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Add Item")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
            }
            .offset(y: -8)

            TabBarButton(icon: "cart", label: "Shopping", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            TabBarButton(icon: "doc.text", label: "Receipts", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .frame(height: 64)
        .padding(.top, 4)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 22)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: -2)
        }
        .background {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .accentColor : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

extension View {
    func withGearIcon(showMoreMenu: Binding<Bool>) -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMoreMenu.wrappedValue = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                }
            }
        }
    }
}

struct MoreMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMenuItem: MenuItem?

    enum MenuItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case mealPlan = "Meal Plan"
        case recipes = "Recipes"
        case assistant = "Assistant"
        case insights = "Insights"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard:
                return "house"
            case .mealPlan:
                return "calendar.badge.clock"
            case .recipes:
                return "book"
            case .assistant:
                return "sparkles"
            case .insights:
                return "chart.bar"
            case .settings:
                return "gear"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(MenuItem.allCases) { item in
                    Button {
                        selectedMenuItem = item
                    } label: {
                        HStack {
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundColor(.accentColor)
                                .frame(width: 32)
                            Text(item.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(item: $selectedMenuItem) { item in
                switch item {
                case .dashboard:
                    DashboardView()
                case .mealPlan:
                    MealPlanListView()
                case .recipes:
                    RecipesListView(showAddRecipe: .constant(false))
                case .assistant:
                    ChatView()
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            PantryItem.self, Category.self, StorageLocation.self,
            ShoppingListItem.self, Recipe.self, RecipeIngredient.self,
            RecipeInstruction.self, RecipeCategory.self, RecipeTag.self,
            RecipeCookingNote.self, RecipeCollection.self,
            Receipt.self, ReceiptItem.self, BarcodeMapping.self,
            MealPlan.self, MealPlanEntry.self, MealPlanConstraintProfile.self,
            MealPlanGeneration.self, MealPlanEntryReason.self, MealPlanFeedback.self
        ], inMemory: true)
}
