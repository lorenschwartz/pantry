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

    @Binding var showAddItem: Bool

    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var selectedLocation: StorageLocation?
    @State private var sortOrder: SortOrder = .name
    @State private var showingFilters = false
    @State private var hasAppliedUITestSearchSeed = false
    /// Set to a non-nil item when a decrement would bring quantity to zero;
    /// triggers the "Remove from pantry?" confirmation dialog.
    @State private var itemPendingDelete: PantryItem?
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case expiration = "Expiration"
        case dateAdded = "Date Added"
        case quantity = "Quantity"
    }
    
    var filteredItems: [PantryItem] {
        var result = items.filter { !$0.isArchived }
        
        // Search filter
        result = PantrySearchService.filter(items: result, query: searchText)
        
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
    
    // MARK: - Summary Bar

    private var summaryBar: some View {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search items", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .accessibilityLabel("pantry.searchField")
                .accessibilityIdentifier("pantry.searchField")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
                .accessibilityIdentifier("pantry.clearSearchButton")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }

    var body: some View {
        NavigationStack {
            Group {
                // Item list
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Items" : "No Matches",
                        systemImage: "cabinet",
                        description: Text(searchText.isEmpty ? "Add your first pantry item to get started" : "No items match your search")
                    )
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                PantryItemRow(
                                    item: item,
                                    onDecrement: {
                                        let step = item.quantityStepSize
                                        if item.quantity - step <= 0 {
                                            // Prompt instead of silently hitting zero
                                            itemPendingDelete = item
                                        } else {
                                            adjustQuantity(item, by: -step)
                                        }
                                    },
                                    onIncrement: {
                                        adjustQuantity(item, by: item.quantityStepSize)
                                    }
                                )
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
                            .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.horizontal, 0, for: .scrollContent)
                    .contentMargins(.top, 0, for: .scrollContent)
                }
            }
            // Pin the summary bar above the scrollable content without wrapping
            // the List in a VStack (which breaks scroll gesture routing in iOS 26).
            .safeAreaInset(edge: .top, spacing: 0) {
                summaryBar
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                searchBar
            }
            .navigationTitle("Pantry")
            .navigationBarTitleDisplayMode(.inline)
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
                            ForEach(uniqueCategories) { category in
                                Button(category.name) {
                                    selectedCategory = category
                                }
                            }
                        }

                        Menu("Filter by Location") {
                            Button("All Locations") {
                                selectedLocation = nil
                            }
                            ForEach(uniqueLocations) { location in
                                Button(location.name) {
                                    selectedLocation = location
                                }
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddEditItemView()
            }
            .confirmationDialog(
                "Remove \"\(itemPendingDelete?.name ?? "")\"?",
                isPresented: Binding(
                    get: { itemPendingDelete != nil },
                    set: { if !$0 { itemPendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove from Pantry", role: .destructive) {
                    if let item = itemPendingDelete {
                        deleteItem(item)
                    }
                    itemPendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    itemPendingDelete = nil
                }
            } message: {
                Text("Decrementing this item would bring its quantity to zero.")
            }
            .onAppear {
                initializeDefaultData()
                applyUITestSearchSeedIfNeeded()
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
    
    // MARK: - Deduplicated Filter Sources

    /// Categories sorted by sortOrder with duplicate names removed (defensive guard
    /// against the seeding race condition that could insert the defaults twice).
    private var uniqueCategories: [Category] {
        var seen = Set<String>()
        return categories
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .filter { seen.insert($0.name).inserted }
    }

    /// Locations sorted by sortOrder with duplicate names removed.
    private var uniqueLocations: [StorageLocation] {
        var seen = Set<String>()
        return locations
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .filter { seen.insert($0.name).inserted }
    }

    // MARK: - Data Initialisation

    private func initializeDefaultData() {
        // Query the store directly rather than using the @Query property, which can be
        // stale at onAppear time and cause duplicate inserts on repeated appearances.
        let categoryCount = (try? modelContext.fetchCount(FetchDescriptor<Category>())) ?? 0
        if categoryCount == 0 {
            for category in Category.defaultCategories {
                modelContext.insert(category)
            }
        }
        // Note: if duplicates exist from a previous seeding race, uniqueCategories /
        // uniqueLocations (above) hide them in the UI safely. We do NOT delete them
        // here — deleting SwiftData objects while @Query holds live references to them
        // causes a fatal "backing data invalidated" crash.

        let locationCount = (try? modelContext.fetchCount(FetchDescriptor<StorageLocation>())) ?? 0
        if locationCount == 0 {
            for location in StorageLocation.defaultLocations {
                modelContext.insert(location)
            }
        }

        try? modelContext.save()
    }

    private func applyUITestSearchSeedIfNeeded() {
        guard !hasAppliedUITestSearchSeed else { return }
        hasAppliedUITestSearchSeed = true
        guard searchText.isEmpty else { return }

        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-UITestPantrySearchQuery"),
              arguments.indices.contains(flagIndex + 1) else {
            return
        }

        searchText = arguments[flagIndex + 1]
    }
}

#Preview {
    PantryListView(showAddItem: .constant(false))
        .modelContainer(for: [PantryItem.self, Category.self, StorageLocation.self], inMemory: true)
}
