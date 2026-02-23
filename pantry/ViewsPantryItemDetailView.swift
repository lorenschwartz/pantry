//
//  ItemDetailView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var item: PantryItem
    
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showRecipeSuggestions = false
    
    @Query private var recipes: [Recipe]
    @Query private var pantryItems: [PantryItem]
    
    private var recipesUsingThisItem: [Recipe] {
        recipes.filter { recipe in
            recipe.ingredients?.contains { ingredient in
                ingredient.name.localizedCaseInsensitiveContains(item.name) ||
                item.name.localizedCaseInsensitiveContains(ingredient.name)
            } ?? false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Item Image
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                
                // Quick Info Cards
                HStack(spacing: 12) {
                    InfoCard(
                        title: "Quantity",
                        value: item.quantity.formatted(),
                        unit: item.unit,
                        icon: "number",
                        color: .blue
                    )
                    
                    if let price = item.price {
                        InfoCard(
                            title: "Price",
                            value: String(format: "%.2f", price),
                            unit: "$",
                            icon: "dollarsign.circle",
                            color: .green
                        )
                    }
                    
                    if let daysUntil = item.daysUntilExpiration {
                        InfoCard(
                            title: "Expires In",
                            value: "\(abs(daysUntil))",
                            unit: "days",
                            icon: "calendar",
                            color: item.isExpired ? .red : (item.isExpiringSoon ? .orange : .green)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Status Badges
                HStack(spacing: 8) {
                    if item.isExpired {
                        StatusBadge(title: "Expired", icon: "exclamationmark.triangle.fill", color: .red)
                    } else if item.isExpiringSoon {
                        StatusBadge(title: "Expiring Soon", icon: "clock.badge.exclamationmark", color: .orange)
                    }
                    
                    if item.isLowStock {
                        StatusBadge(title: "Low Stock", icon: "arrow.down.circle", color: .orange)
                    }
                }
                .padding(.horizontal)
                
                // Details Section
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Name", value: item.name)
                    
                    if let brand = item.brand {
                        DetailRow(label: "Brand", value: brand)
                    }
                    
                    if let category = item.category {
                        HStack {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.name)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color.opacity(0.2))
                            .foregroundStyle(category.color)
                            .clipShape(Capsule())
                        }
                    }
                    
                    if let location = item.location {
                        HStack {
                            Text("Location")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack {
                                Image(systemName: location.iconName)
                                Text(location.name)
                            }
                        }
                    }
                    
                    Divider()
                    
                    DetailRow(label: "Purchase Date", value: item.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    
                    if let expirationDate = item.expirationDate {
                        DetailRow(label: "Expiration Date", value: expirationDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    
                    if let barcode = item.barcode {
                        DetailRow(label: "Barcode", value: barcode)
                    }
                    
                    if let description = item.itemDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(description)
                        }
                    }
                    
                    if let notes = item.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(notes)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.yellow.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    Divider()
                    
                    DetailRow(label: "Added", value: item.createdDate.formatted(date: .abbreviated, time: .shortened))
                    
                    DetailRow(label: "Last Modified", value: item.modifiedDate.formatted(date: .abbreviated, time: .shortened))
                    
                    if let modifiedBy = item.modifiedBy {
                        DetailRow(label: "Modified By", value: modifiedBy)
                    }
                }
                .padding(.horizontal)
                
                // Recipes Using This Item
                if !recipesUsingThisItem.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recipes Using This Item")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(recipesUsingThisItem.prefix(5)) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                HStack {
                                    if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: "fork.knife")
                                            .frame(width: 50, height: 50)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(recipe.name)
                                            .font(.subheadline)
                                        Text("\(recipe.totalTime) min")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // Quick Actions
                VStack(spacing: 12) {
                    Button {
                        showRecipeSuggestions = true
                    } label: {
                        Label("Find Recipes", systemImage: "book")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        addToShoppingList()
                    } label: {
                        Label("Add to Shopping List", systemImage: "cart.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Item", systemImage: "pencil")
                    }
                    
                    Button {
                        duplicateItem()
                    } label: {
                        Label("Duplicate Item", systemImage: "doc.on.doc")
                    }
                    
                    ShareLink(item: "\(item.name) - \(item.quantity) \(item.unit)") {
                        Label("Share Item", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Item", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditItemView(item: item)
        }
        .sheet(isPresented: $showRecipeSuggestions) {
            NavigationStack {
                RecipeSuggestionsView()
                    .navigationTitle("Recipe Suggestions")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showRecipeSuggestions = false
                            }
                        }
                    }
            }
        }
        .alert("Delete Item?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Actions
    
    private func deleteItem() {
        modelContext.delete(item)
        dismiss()
    }
    
    private func duplicateItem() {
        let duplicate = PantryItem(
            name: "\(item.name) (Copy)",
            description: item.itemDescription,
            quantity: item.quantity,
            unit: item.unit,
            brand: item.brand,
            price: item.price,
            purchaseDate: Date(),
            expirationDate: item.expirationDate,
            barcode: item.barcode,
            imageData: item.imageData,
            notes: item.notes,
            category: item.category,
            location: item.location
        )
        
        modelContext.insert(duplicate)
    }
    
    private func addToShoppingList() {
        let shoppingItem = ShoppingListItem(
            name: item.name,
            quantity: 1,
            unit: item.unit,
            notes: "From pantry",
            estimatedPrice: item.price,
            category: item.category,
            relatedPantryItemID: item.id
        )
        
        modelContext.insert(shoppingItem)
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

struct StatusBadge: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: PantryItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let item = PantryItem.sampleItems[0]
    container.mainContext.insert(item)
    
    return NavigationStack {
        ItemDetailView(item: item)
    }
    .modelContainer(container)
}
