//
//  PantryListView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct PantryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PantryItem.name) private var items: [PantryItem]
    @Query private var categories: [Category]
    @Query private var locations: [StorageLocation]
    
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var selectedLocation: StorageLocation?
    @State private var sortOrder: SortOrder = .name
    @State private var showingAddItem = false
    @State private var showingFilters = false
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case expiration = "Expiration"
        case dateAdded = "Date Added"
        case quantity = "Quantity"
    }
    
    var filteredItems: [PantryItem] {
        var result = items.filter { !$0.isArchived }
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Category filter
        if let selectedCategory {
            result = result.filter { $0.category?.id == selectedCategory.id }
        }
        
        // Location filter
        if let selectedLocation {
            result = result.filter { $0.location?.id == selectedLocation.id }
        }
        
        // Sort
        switch sortOrder {
        case .name:
            result.sort { $0.name < $1.name }
        case .expiration:
            result.sort { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
        case .dateAdded:
            result.sort { $0.createdDate > $1.createdDate }
        case .quantity:
            result.sort { $0.quantity < $1.quantity }
        }
        
        return result
    }
    
    var inventorySummary: String {
        "\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")"
    }
    
    var totalValue: Double {
        filteredItems.compactMap { $0.price }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(inventorySummary)
                            .font(.headline)
                        if totalValue > 0 {
                            Text("Total Value: $\(totalValue, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    
                    // Filter indicators
                    if selectedCategory != nil || selectedLocation != nil {
                        Button(action: clearFilters) {
                            Label("Clear Filters", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .labelStyle(.iconOnly)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                
                // Item list
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "cabinet",
                        description: Text(searchText.isEmpty ? "Add your first pantry item to get started" : "No items match your search")
                    )
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                PantryItemRow(item: item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    // Quick edit action
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    adjustQuantity(item, by: -1)
                                } label: {
                                    Label("Decrease", systemImage: "minus.circle")
                                }
                                .tint(.orange)
                                
                                Button {
                                    adjustQuantity(item, by: 1)
                                } label: {
                                    Label("Increase", systemImage: "plus.circle")
                                }
                                .tint(.green)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search items")
                }
            }
            .navigationTitle("Pantry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        
                        Divider()
                        
                        Menu("Filter by Category") {
                            Button("All Categories") {
                                selectedCategory = nil
                            }
                            ForEach(categories.sorted(by: { $0.sortOrder < $1.sortOrder })) { category in
                                Button(category.name) {
                                    selectedCategory = category
                                }
                            }
                        }
                        
                        Menu("Filter by Location") {
                            Button("All Locations") {
                                selectedLocation = nil
                            }
                            ForEach(locations.sorted(by: { $0.sortOrder < $1.sortOrder })) { location in
                                Button(location.name) {
                                    selectedLocation = location
                                }
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditItemView()
            }
            .onAppear {
                initializeDefaultData()
            }
        }
    }
    
    private func clearFilters() {
        selectedCategory = nil
        selectedLocation = nil
    }
    
    private func deleteItem(_ item: PantryItem) {
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }
    
    private func adjustQuantity(_ item: PantryItem, by amount: Double) {
        withAnimation {
            item.quantity = max(0, item.quantity + amount)
            item.modifiedDate = Date()
            try? modelContext.save()
        }
    }
    
    private func initializeDefaultData() {
        // Add default categories if none exist
        if categories.isEmpty {
            for category in Category.defaultCategories {
                modelContext.insert(category)
            }
        }
        
        // Add default locations if none exist
        if locations.isEmpty {
            for location in StorageLocation.defaultLocations {
                modelContext.insert(location)
            }
        }
        
        try? modelContext.save()
    }
}

#Preview {
    PantryListView()
        .modelContainer(for: [PantryItem.self, Category.self, StorageLocation.self], inMemory: true)
}
