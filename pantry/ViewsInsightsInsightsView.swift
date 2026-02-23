//
//  InsightsView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var pantryItems: [PantryItem]
    @Query private var recipes: [Recipe]
    @Query private var shoppingItems: [ShoppingListItem]
    @Query private var categories: [Category]
    
    private var totalItems: Int {
        pantryItems.filter { !$0.isArchived }.count
    }
    
    private var totalValue: Double {
        pantryItems.filter { !$0.isArchived }.compactMap { $0.price }.reduce(0, +)
    }
    
    private var expiringItems: [PantryItem] {
        pantryItems.filter { $0.isExpiringSoon && !$0.isExpired }
    }
    
    private var expiredItems: [PantryItem] {
        pantryItems.filter { $0.isExpired }
    }
    
    private var lowStockItems: [PantryItem] {
        pantryItems.filter { $0.isLowStock && !$0.isExpired }
    }
    
    private var itemsByCategory: [(Category, Int)] {
        let activeItems = pantryItems.filter { !$0.isArchived }
        return categories.compactMap { category in
            let count = activeItems.filter { $0.category?.id == category.id }.count
            return count > 0 ? (category, count) : nil
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview Cards
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Total Items",
                                value: "\(totalItems)",
                                icon: "cube.box.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Total Value",
                                value: "$\(totalValue, specifier: "%.0f")",
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )
                        }
                        
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Recipes",
                                value: "\(recipes.count)",
                                icon: "book.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Shopping List",
                                value: "\(shoppingItems.filter { !$0.isChecked }.count)",
                                icon: "cart.fill",
                                color: .purple
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Alerts Section
                    if !expiredItems.isEmpty || !expiringItems.isEmpty || !lowStockItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Alerts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                if !expiredItems.isEmpty {
                                    NavigationLink {
                                        ExpiredItemsView(items: expiredItems)
                                    } label: {
                                        AlertCard(
                                            title: "Expired Items",
                                            count: expiredItems.count,
                                            icon: "exclamationmark.triangle.fill",
                                            color: .red
                                        )
                                    }
                                }
                                
                                if !expiringItems.isEmpty {
                                    NavigationLink {
                                        ExpiringItemsView(items: expiringItems)
                                    } label: {
                                        AlertCard(
                                            title: "Expiring Soon",
                                            count: expiringItems.count,
                                            icon: "clock.badge.exclamationmark",
                                            color: .orange
                                        )
                                    }
                                }
                                
                                if !lowStockItems.isEmpty {
                                    NavigationLink {
                                        LowStockItemsView(items: lowStockItems)
                                    } label: {
                                        AlertCard(
                                            title: "Low Stock",
                                            count: lowStockItems.count,
                                            icon: "arrow.down.circle.fill",
                                            color: .yellow
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Items by Category Chart
                    if !itemsByCategory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Items by Category")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart(itemsByCategory, id: \.0.id) { category, count in
                                BarMark(
                                    x: .value("Count", count),
                                    y: .value("Category", category.name)
                                )
                                .foregroundStyle(category.color)
                            }
                            .frame(height: CGFloat(itemsByCategory.count) * 40)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            NavigationLink {
                                RecipeSuggestionsView()
                            } label: {
                                QuickActionCard(
                                    title: "What Can I Make?",
                                    icon: "fork.knife",
                                    color: .blue
                                )
                            }
                            
                            NavigationLink {
                                PantryListView()
                            } label: {
                                QuickActionCard(
                                    title: "Browse Pantry",
                                    icon: "cabinet",
                                    color: .green
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AlertCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text("\(count) item\(count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Detail Views

struct ExpiredItemsView: View {
    let items: [PantryItem]
    
    var body: some View {
        List(items) { item in
            NavigationLink(destination: ItemDetailView(item: item)) {
                PantryItemRow(item: item)
            }
        }
        .navigationTitle("Expired Items")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExpiringItemsView: View {
    let items: [PantryItem]
    
    var body: some View {
        List(items.sorted { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }) { item in
            NavigationLink(destination: ItemDetailView(item: item)) {
                PantryItemRow(item: item)
            }
        }
        .navigationTitle("Expiring Soon")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LowStockItemsView: View {
    let items: [PantryItem]
    
    var body: some View {
        List(items.sorted { $0.quantity < $1.quantity }) { item in
            NavigationLink(destination: ItemDetailView(item: item)) {
                PantryItemRow(item: item)
            }
        }
        .navigationTitle("Low Stock")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: PantryItem.self,
        Recipe.self,
        ShoppingListItem.self,
        Category.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // Add sample data
    for item in PantryItem.sampleItems {
        container.mainContext.insert(item)
    }
    
    for recipe in Recipe.sampleRecipes {
        container.mainContext.insert(recipe)
    }
    
    for category in Category.defaultCategories {
        container.mainContext.insert(category)
    }
    
    return InsightsView()
        .modelContainer(container)
}
