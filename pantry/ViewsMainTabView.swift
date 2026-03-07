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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PantryListView()
                .tabItem {
                    Label("Pantry", systemImage: "cabinet")
                }
                .tag(0)
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
                .tag(1)
            
            RecipesListView()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
                .tag(2)
            
            ReceiptsListView()
                .tabItem {
                    Label("Receipts", systemImage: "doc.text")
                }
                .tag(3)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
                .tag(4)

            ChatView()
                .tabItem {
                    Label("Assistant", systemImage: "sparkles")
                }
                .tag(5)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(6)
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
            Receipt.self, ReceiptItem.self, BarcodeMapping.self
        ], inMemory: true)
}
