//
//  AddEditItemView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var item: PantryItem?
    
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]
    
    @State private var name = ""
    @State private var itemDescription = ""
    @State private var quantity: Double = 1.0
    @State private var unit = "item"
    @State private var brand = ""
    @State private var price = ""
    @State private var purchaseDate = Date()
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var barcode = ""
    @State private var notes = ""
    @State private var selectedCategory: Category?
    @State private var selectedLocation: StorageLocation?
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingBarcodeScanner = false

    let commonUnits = ["item", "lb", "oz", "kg", "g", "L", "mL", "cup", "tbsp", "tsp", "gallon", "bottle", "can", "bag", "box", "bunch", "loaf", "package"]
    
    var isEditing: Bool {
        item != nil
    }
    
    init(item: PantryItem? = nil) {
        self.item = item
        
        if let item = item {
            _name = State(initialValue: item.name)
            _itemDescription = State(initialValue: item.itemDescription ?? "")
            _quantity = State(initialValue: item.quantity)
            _unit = State(initialValue: item.unit)
            _brand = State(initialValue: item.brand ?? "")
            _price = State(initialValue: item.price != nil ? String(format: "%.2f", item.price!) : "")
            _purchaseDate = State(initialValue: item.purchaseDate)
            _hasExpirationDate = State(initialValue: item.expirationDate != nil)
            _expirationDate = State(initialValue: item.expirationDate ?? Date().addingTimeInterval(7 * 24 * 60 * 60))
            _barcode = State(initialValue: item.barcode ?? "")
            _notes = State(initialValue: item.notes ?? "")
            _selectedImageData = State(initialValue: item.imageData)
            _selectedCategory = State(initialValue: item.category)
            _selectedLocation = State(initialValue: item.location)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                Section("Basic Information") {
                    TextField("Item Name", text: $name)
                    
                    TextField("Description (optional)", text: $itemDescription, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Brand (optional)", text: $brand)
                    
                    // Photo Picker
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Item Photo")
                                    .font(.headline)
                                Text("Tap to select")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }
                
                // Quantity & Unit
                Section("Quantity") {
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
                        Text("Price")
                        Spacer()
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("$")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Organization
                Section("Organization") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                    
                    Picker("Storage Location", selection: $selectedLocation) {
                        Text("None").tag(nil as StorageLocation?)
                        ForEach(locations) { location in
                            HStack {
                                Image(systemName: location.iconName)
                                Text(location.name)
                            }
                            .tag(location as StorageLocation?)
                        }
                    }
                }
                
                // Dates
                Section("Dates") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    Toggle("Has Expiration Date", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                    }
                }
                
                // Additional Info
                Section("Additional Information") {
                    HStack {
                        TextField("Barcode (optional)", text: $barcode)
                            .keyboardType(.numberPad)
                        Spacer()
                        Button {
                            showingBarcodeScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { scannedBarcode in
                    barcode = scannedBarcode
                    autoFillFromBarcode(scannedBarcode)
                }
            }
        }
    }

    // MARK: - Barcode Auto-Fill

    private func autoFillFromBarcode(_ scannedBarcode: String) {
        let descriptor = FetchDescriptor<BarcodeMapping>(
            predicate: #Predicate { $0.barcode == scannedBarcode }
        )
        guard let mapping = try? modelContext.fetch(descriptor).first else { return }

        // Only auto-fill fields the user hasn't already touched
        if name.isEmpty { name = mapping.productName }
        if brand.isEmpty, let mappedBrand = mapping.brand { brand = mappedBrand }
        if unit == "item", mapping.defaultUnit != "item" { unit = mapping.defaultUnit }
        if selectedCategory == nil { selectedCategory = mapping.category }
        if price.isEmpty, let avg = mapping.averagePrice {
            price = String(format: "%.2f", avg)
        }

        mapping.recordScan()
    }

    // MARK: - Actions
    
    private func saveItem() {
        let priceValue = Double(price.trimmingCharacters(in: .whitespacesAndNewlines))
        
        if let item = item {
            // Update existing item
            item.name = name
            item.itemDescription = itemDescription.isEmpty ? nil : itemDescription
            item.quantity = quantity
            item.unit = unit
            item.brand = brand.isEmpty ? nil : brand
            item.price = priceValue
            item.purchaseDate = purchaseDate
            item.expirationDate = hasExpirationDate ? expirationDate : nil
            item.barcode = barcode.isEmpty ? nil : barcode
            item.notes = notes.isEmpty ? nil : notes
            item.imageData = selectedImageData
            item.category = selectedCategory
            item.location = selectedLocation
            item.modifiedDate = Date()
        } else {
            // Create new item
            let newItem = PantryItem(
                name: name,
                description: itemDescription.isEmpty ? nil : itemDescription,
                quantity: quantity,
                unit: unit,
                brand: brand.isEmpty ? nil : brand,
                price: priceValue,
                purchaseDate: purchaseDate,
                expirationDate: hasExpirationDate ? expirationDate : nil,
                barcode: barcode.isEmpty ? nil : barcode,
                imageData: selectedImageData,
                notes: notes.isEmpty ? nil : notes,
                category: selectedCategory,
                location: selectedLocation
            )
            
            modelContext.insert(newItem)
            
            // Learn barcode if provided
            if !barcode.isEmpty {
                learnBarcode(barcode: barcode, item: newItem)
            }
        }
        
        dismiss()
    }
    
    private func learnBarcode(barcode: String, item: PantryItem) {
        // Check if barcode already exists
        let descriptor = FetchDescriptor<BarcodeMapping>(
            predicate: #Predicate { $0.barcode == barcode }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.recordScan()
        } else {
            // Create new barcode mapping
            let mapping = BarcodeMapping(
                barcode: barcode,
                productName: item.name,
                brand: item.brand,
                defaultUnit: item.unit,
                category: item.category,
                averagePrice: item.price
            )
            modelContext.insert(mapping)
        }
    }
}

// MARK: - Preview
#Preview("New Item") {
    AddEditItemView()
        .modelContainer(for: [PantryItem.self, Category.self, StorageLocation.self], inMemory: true)
}

#Preview("Edit Item") {
    let container = try! ModelContainer(
        for: PantryItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let item = PantryItem.sampleItems[0]
    container.mainContext.insert(item)
    
    return AddEditItemView(item: item)
        .modelContainer(container)
}
