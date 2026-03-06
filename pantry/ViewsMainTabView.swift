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
        ZStack(alignment: .bottom) {
            // Main content area with gear icon toolbar
            Group {
                switch selectedTab {
                case 0:
                    PantryListView(showAddItem: $showAddItem)
                        .withGearIcon(showMoreMenu: $showMoreMenu)
                case 1:
                    ShoppingListView(showAddItem: $showAddShoppingItem)
                        .withGearIcon(showMoreMenu: $showMoreMenu)
                case 2:
                    RecipesListView(showAddRecipe: $showAddRecipe)
                        .withGearIcon(showMoreMenu: $showMoreMenu)
                case 3:
                    ReceiptsListView(showingSourcePicker: $showAddReceipt)
                        .withGearIcon(showMoreMenu: $showMoreMenu)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
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
        case 0: // Pantry
            showAddItem = true
        case 1: // Shopping
            showAddShoppingItem = true
        case 2: // Recipes
            showAddRecipe = true
        case 3: // Receipts
            showAddReceipt = true
        default:
            break
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Left tabs
            TabBarButton(
                icon: "cabinet",
                label: "Pantry",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            TabBarButton(
                icon: "cart",
                label: "Shopping",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            // Center Add Button
            Button(action: onAddTapped) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -8)

            // Right tabs
            TabBarButton(
                icon: "book",
                label: "Recipes",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }

            TabBarButton(
                icon: "doc.text",
                label: "Receipts",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
        }
        .frame(height: 50)
        .padding(.bottom, 34) // Safe area for home indicator
        .background(
            Color(uiColor: .systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
    }
}

// MARK: - Tab Bar Button

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

// MARK: - View Extension for Gear Icon

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

// MARK: - More Menu View

struct MoreMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMenuItem: MenuItem?

    enum MenuItem: String, CaseIterable, Identifiable {
        case insights = "Insights"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .insights: return "chart.bar"
            case .settings: return "gear"
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
        .modelContainer(for: [PantryItem.self, Category.self, StorageLocation.self], inMemory: true)
}
