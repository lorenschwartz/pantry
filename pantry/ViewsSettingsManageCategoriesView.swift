//
//  ManageCategoriesView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import SwiftData

// MARK: - Manage Categories List

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showingAddSheet = false
    @State private var editingCategory: Category?

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editingCategory = category
                } label: {
                    CategoryRow(category: category)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditCategoryView()
        }
        .sheet(item: $editingCategory) { category in
            AddEditCategoryView(category: category)
        }
        .overlay {
            if categories.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "tag",
                    description: Text("Tap + to create a category.")
                )
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            // Allow deleting all categories (custom and default)
            modelContext.delete(category)
        }
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.body)
                .foregroundStyle(category.color)
                .frame(width: 34, height: 34)
                .background(category.color.opacity(0.15))
                .clipShape(Circle())

            Text(category.name)

            Spacer()

            if category.isDefault {
                Text("Default")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Add / Edit Category Sheet

struct AddEditCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var category: Category?

    @State private var name = ""
    @State private var selectedColor = Color.blue
    @State private var selectedIcon = "tag"

    var isEditing: Bool { category != nil }

    // Common SF Symbols appropriate for food/pantry categories
    private let iconOptions: [String] = [
        "tag", "leaf", "drop", "flame", "square.grid.2x2", "sparkles",
        "drop.triangle", "cup.and.saucer", "popcorn", "snowflake", "cylinder",
        "birthday.cake", "cart", "star", "heart", "bookmark",
        "bag", "archivebox", "tray", "folder",
        "fish", "carrot", "fork.knife", "wineglass",
        "takeoutbag.and.cup.and.straw", "refrigerator", "cabinet", "house"
    ]

    init(category: Category? = nil) {
        self.category = category
        if let category {
            _name = State(initialValue: category.name)
            _selectedColor = State(initialValue: category.color)
            _selectedIcon = State(initialValue: category.iconName)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name", text: $name)
                }

                Section("Color") {
                    ColorPicker("Category Color", selection: $selectedColor, supportsOpacity: false)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                    .background(selectedIcon == icon ? selectedColor : Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .foregroundStyle(selectedColor)
                            .frame(width: 34, height: 34)
                            .background(selectedColor.opacity(0.15))
                            .clipShape(Circle())

                        Text(name.isEmpty ? "Category Name" : name)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let hex = selectedColor.toHex() ?? "#007AFF"
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let category {
            category.name = trimmedName
            category.colorHex = hex
            category.iconName = selectedIcon
        } else {
            let newCategory = Category(
                name: trimmedName,
                colorHex: hex,
                iconName: selectedIcon
            )
            modelContext.insert(newCategory)
        }
        dismiss()
    }
}

// MARK: - Previews

#Preview("Manage Categories") {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(for: [Category.self, PantryItem.self], inMemory: true)
}

#Preview("Add Category") {
    AddEditCategoryView()
        .modelContainer(for: Category.self, inMemory: true)
}

#Preview("Edit Category") {
    let container = try! ModelContainer(
        for: Category.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let category = Category.defaultCategories[0]
    container.mainContext.insert(category)
    return AddEditCategoryView(category: category)
        .modelContainer(container)
}
