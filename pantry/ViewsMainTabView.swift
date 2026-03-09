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
    @State private var showSettings = false
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
                    .withGearIcon(showSettings: $showSettings)
            case 3:
                ShoppingListView(showAddItem: $showAddShoppingItem)
                    .withGearIcon(showSettings: $showSettings)
            case 4:
                NavigationStack {
                    MealPlanListView()
                }
                    .withGearIcon(showSettings: $showSettings)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
    func withGearIcon(showSettings: Binding<Bool>) -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings.wrappedValue = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
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
