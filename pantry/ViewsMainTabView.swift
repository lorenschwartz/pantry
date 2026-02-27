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
    @Query private var pantryItems: [PantryItem]

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

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
        .onAppear { scheduleNotifications() }
        .onChange(of: pantryItems) { _, _ in scheduleNotifications() }
    }

    private func scheduleNotifications() {
        NotificationService.requestPermission()
        NotificationService.scheduleExpirationNotifications(for: pantryItems)
        let lowStock = LowStockService.detectLowStockItems(from: pantryItems)
        if !lowStock.isEmpty {
            NotificationService.scheduleLowStockNotification(for: lowStock)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [PantryItem.self, Category.self, StorageLocation.self], inMemory: true)
}
