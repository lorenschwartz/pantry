//
//  ShoppingListView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ShoppingListItem.priority, order: .reverse) private var allItems: [ShoppingListItem]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showAddItem = false
    @State private var showCheckedItems = false
    /// Persisted across sessions; defaults to aisle grouping.
    @AppStorage("shoppingListSortBy") private var sortByRaw: String = SortOption.aisle.rawValue

    private var sortBy: SortOption { SortOption(rawValue: sortByRaw) ?? .aisle }

    private var sortByBinding: Binding<SortOption> {
        Binding(get: { sortBy }, set: { sortByRaw = $0.rawValue })
    }

    enum SortOption: String {
        case priority, aisle
    }

    // MARK: - Derived Collections

    private var uncheckedItems: [ShoppingListItem] {
        allItems.filter { !$0.isChecked }.sorted { $0.priority > $1.priority }
    }

    private var checkedItems: [ShoppingListItem] {
        allItems.filter { $0.isChecked }
    }

    private var estimatedTotal: Double {
        uncheckedItems.compactMap { $0.estimatedPrice }.reduce(0, +)
    }

    /// Groups unchecked items by aisle, in category sort order, with "Other" last.
    private var itemsByAisle: [(aisleName: String, items: [ShoppingListItem], category: Category?)] {
        let unchecked = allItems.filter { !$0.isChecked }

        var grouped: [String: [ShoppingListItem]] = [:]
        for item in unchecked {
            let key = item.category?.name ?? "Other"
            grouped[key, default: []].append(item)
        }

        var result: [(aisleName: String, items: [ShoppingListItem], category: Category?)] = []

        // Known categories in sort order (from @Query).
        // Deduplicate by name — if the store contains duplicate Category rows with the
        // same name (e.g. from a seeding race condition), we must only emit one section.
        var seenNames = Set<String>()
        for category in categories {
            guard !seenNames.contains(category.name) else { continue }
            seenNames.insert(category.name)
            if let items = grouped[category.name], !items.isEmpty {
                result.append((category.name, items, category))
            }
        }

        // Uncategorized at the end
        if let otherItems = grouped["Other"], !otherItems.isEmpty {
            result.append(("Other", otherItems, nil))
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Bar
                if !uncheckedItems.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(uncheckedItems.count) item\(uncheckedItems.count == 1 ? "" : "s") to buy")
                                .font(.headline)
                            if estimatedTotal > 0 {
                                Text("Estimated: $\(estimatedTotal, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if !checkedItems.isEmpty {
                            Button {
                                withAnimation {
                                    showCheckedItems.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(checkedItems.count) checked")
                                        .font(.caption)
                                    Image(systemName: showCheckedItems ? "chevron.up" : "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                }

                // Shopping List
                if uncheckedItems.isEmpty && checkedItems.isEmpty {
                    ContentUnavailableView {
                        Label("Shopping List Empty", systemImage: "cart")
                    } description: {
                        Text("Add items manually or they'll be added automatically when pantry items run low")
                    } actions: {
                        Button("Add Item") {
                            showAddItem = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if sortBy == .priority {
                            // ── Priority Mode: flat sorted list ──────────────
                            if !uncheckedItems.isEmpty {
                                Section {
                                    ForEach(uncheckedItems) { item in
                                        ShoppingListItemRow(item: item)
                                    }
                                    .onDelete { indexSet in
                                        deleteItems(at: indexSet, from: uncheckedItems)
                                    }
                                } header: {
                                    Text("To Buy")
                                }
                            }
                        } else {
                            // ── Aisle Mode: sectioned by grocery store aisle ──
                            ForEach(itemsByAisle, id: \.aisleName) { group in
                                Section {
                                    ForEach(group.items) { item in
                                        ShoppingListItemRow(item: item)
                                    }
                                    .onDelete { indexSet in
                                        deleteItems(at: indexSet, from: group.items)
                                    }
                                } header: {
                                    HStack(spacing: 6) {
                                        if let category = group.category {
                                            Image(systemName: category.iconName)
                                                .foregroundStyle(category.color)
                                        } else {
                                            Image(systemName: "cart")
                                                .foregroundStyle(Color.secondary)
                                        }
                                        Text(group.aisleName)
                                        Spacer()
                                        Text("\(group.items.count)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        // ── Checked Items (both modes) ────────────────────────
                        if showCheckedItems && !checkedItems.isEmpty {
                            Section {
                                ForEach(checkedItems) { item in
                                    ShoppingListItemRow(item: item)
                                }
                                .onDelete { indexSet in
                                    deleteItems(at: indexSet, from: checkedItems)
                                }
                            } header: {
                                HStack {
                                    Text("Completed")
                                    Spacer()
                                    Button("Clear All") {
                                        clearCheckedItems()
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }

                if !allItems.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Picker("View Mode", selection: sortByBinding) {
                                Label("Group by Aisle", systemImage: "cart.badge.questionmark")
                                    .tag(SortOption.aisle)
                                Label("Sort by Priority", systemImage: "arrow.up.arrow.down")
                                    .tag(SortOption.priority)
                            }

                            Divider()

                            Button(role: .destructive) {
                                clearAll()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Label("Options", systemImage: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddShoppingListItemView()
            }
            .onAppear {
                autoCategorizeMissingItems()
            }
        }
    }

    // MARK: - Actions

    /// Auto-categorizes any items that have no category set.
    /// Items already manually categorized are left unchanged.
    private func autoCategorizeMissingItems() {
        AisleCategorizationService.categorizeUncategorized(
            items: Array(allItems),
            categories: Array(categories)
        )
        try? modelContext.save()
    }

    private func deleteItems(at offsets: IndexSet, from items: [ShoppingListItem]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func clearCheckedItems() {
        withAnimation {
            for item in checkedItems {
                modelContext.delete(item)
            }
        }
    }

    private func clearAll() {
        withAnimation {
            for item in allItems {
                modelContext.delete(item)
            }
        }
    }
}

// MARK: - Shopping List Item Row

struct ShoppingListItemRow: View {
    @Bindable var item: ShoppingListItem

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    item.isChecked.toggle()
                    if item.isChecked {
                        item.checkedDate = Date()
                    } else {
                        item.checkedDate = nil
                    }
                }
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .strikethrough(item.isChecked)

                    if item.priority == 2 {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(item.quantity.formatted()) \(item.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let price = item.estimatedPrice {
                        Text("≈ $\(price, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .opacity(item.isChecked ? 0.6 : 1.0)

            Spacer()

            // Category Badge
            if let category = item.category {
                Image(systemName: category.iconName)
                    .font(.caption)
                    .foregroundStyle(category.color)
                    .padding(6)
                    .background(category.color.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Shopping List Item View

struct AddShoppingListItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name = ""
    @State private var quantity: Double = 1.0
    @State private var unit = "item"
    @State private var notes = ""
    @State private var estimatedPrice = ""
    @State private var priority = 1
    @State private var selectedCategory: Category?
    /// Tracks whether the user has manually chosen a category so auto-suggest stops overwriting it.
    @State private var hasManualCategorySelection = false

    let commonUnits = ["item", "lb", "oz", "kg", "g", "L", "mL", "cup", "tbsp", "tsp", "gallon", "bottle", "can", "bag", "box", "bunch", "loaf", "package"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .onChange(of: name) { _, newName in
                            guard !hasManualCategorySelection else { return }
                            selectedCategory = AisleCategorizationService.suggestCategory(
                                for: newName,
                                from: Array(categories)
                            )
                        }

                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    Picker("Unit", selection: $unit) {
                        ForEach(commonUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }

                    HStack {
                        Text("Estimated Price")
                        Spacer()
                        TextField("0.00", text: $estimatedPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("$")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Organization") {
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(0)
                        Text("Normal").tag(1)
                        Text("High").tag(2)
                    }
                    .pickerStyle(.segmented)

                    Picker("Aisle / Category", selection: Binding(
                        get: { selectedCategory },
                        set: { newValue in
                            selectedCategory = newValue
                            hasManualCategorySelection = true
                        }
                    )) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveItem() {
        let priceValue = Double(estimatedPrice.trimmingCharacters(in: .whitespacesAndNewlines))

        let item = ShoppingListItem(
            name: name,
            quantity: quantity,
            unit: unit,
            notes: notes.isEmpty ? nil : notes,
            estimatedPrice: priceValue,
            priority: priority,
            category: selectedCategory
        )

        modelContext.insert(item)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: ShoppingListItem.self, Category.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    for cat in Category.defaultCategories {
        container.mainContext.insert(cat)
    }

    for item in ShoppingListItem.sampleItems {
        container.mainContext.insert(item)
    }

    return ShoppingListView()
        .modelContainer(container)
}
