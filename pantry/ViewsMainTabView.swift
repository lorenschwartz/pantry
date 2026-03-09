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
    @State private var showAddShoppingItem = false
    @State private var showMoreMenu = false
    @State private var assistantSession = AssistantSessionStore()

    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                NavigationStack {
                    ChatView(session: assistantSession)
                }
            case 1:
                DashboardView(assistantSession: assistantSession)
            case 2:
                PantryListView(showAddItem: $showAddItem)
                    .withGearIcon(showMoreMenu: $showMoreMenu)
            case 3:
                ShoppingListView(showAddItem: $showAddShoppingItem)
                    .withGearIcon(showMoreMenu: $showMoreMenu)
            case 4:
                NavigationStack {
                    MealPlanListView()
                }
                    .withGearIcon(showMoreMenu: $showMoreMenu)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showMoreMenu) {
            MoreMenuView(assistantSession: assistantSession)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "sparkles", label: "Assistant", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabBarButton(icon: "house", label: "Home", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabBarButton(icon: "cabinet", label: "Pantry", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            TabBarButton(icon: "cart", label: "Shopping", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            TabBarButton(icon: "calendar.badge.clock", label: "Plans", isSelected: selectedTab == 4) {
                selectedTab = 4
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
    let assistantSession: AssistantSessionStore

    enum MenuItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case receipts = "Receipts"
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
            case .receipts:
                return "doc.text"
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
                    DashboardView(assistantSession: assistantSession)
                case .receipts:
                    ReceiptsListView(showingSourcePicker: .constant(false))
                case .mealPlan:
                    MealPlanListView()
                case .recipes:
                    RecipesListView(showAddRecipe: .constant(false))
                case .assistant:
                    ChatView(session: assistantSession)
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
