//
//  ReceiptReviewView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import SwiftData

// MARK: - Editable model for the review form

/// Mutable, Identifiable wrapper around `ParsedReceiptItem` used as view state.
struct EditableReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var price: Double?
    var isIncluded: Bool = true

    init(from parsed: ParsedReceiptItem) {
        name = parsed.name
        quantity = parsed.quantity
        unit = parsed.unit
        price = parsed.price
    }
}

// MARK: - ReceiptReviewView

/// Displays OCR-parsed items for user review before adding them to the pantry.
///
/// The user can:
/// - Edit item name, quantity and price inline
/// - Toggle items in/out with the checkbox
/// - Correct the store name and purchase date
struct ReceiptReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let imageData: Data
    let ocrText: String

    @State private var storeName: String
    @State private var purchaseDate: Date
    @State private var items: [EditableReceiptItem]

    let commonUnits = ["item", "lb", "oz", "kg", "g", "gallon", "qt", "dz", "ct", "ea", "pk"]

    init(imageData: Data, ocrText: String) {
        self.imageData = imageData
        self.ocrText = ocrText

        let parsed = ReceiptParsingService.parseReceiptText(ocrText)
        _storeName = State(initialValue: ReceiptParsingService.extractStoreName(from: ocrText) ?? "")
        _purchaseDate = State(
            initialValue: ReceiptParsingService.extractPurchaseDate(from: ocrText) ?? Date())
        _items = State(initialValue: parsed.map { EditableReceiptItem(from: $0) })
    }

    private var includedCount: Int { items.filter(\.isIncluded).count }

    var body: some View {
        NavigationStack {
            Form {
                receiptInfoSection
                itemsSection
                if items.isEmpty { noItemsSection }
            }
            .navigationTitle("Review Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Pantry") { saveReceipt() }
                        .disabled(includedCount == 0)
                }
            }
        }
    }

    // MARK: - Sections

    private var receiptInfoSection: some View {
        Section("Receipt Details") {
            TextField("Store Name", text: $storeName)
            DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
        }
    }

    @ViewBuilder
    private var itemsSection: some View {
        if !items.isEmpty {
            Section {
                ForEach($items) { $item in
                    EditableReceiptItemRow(item: $item, commonUnits: commonUnits)
                }
                .onDelete { offsets in items.remove(atOffsets: offsets) }
            } header: {
                HStack {
                    Text("Items")
                    Spacer()
                    Text("\(includedCount) of \(items.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var noItemsSection: some View {
        Section {
            ContentUnavailableView(
                "No Items Found",
                systemImage: "text.page.slash",
                description: Text("The receipt text could not be parsed. Try scanning again in better light.")
            )
        }
    }

    // MARK: - Save

    private func saveReceipt() {
        let receipt = Receipt(
            storeName: storeName.isEmpty ? nil : storeName,
            purchaseDate: purchaseDate,
            imageData: imageData,
            rawOCRText: ocrText
        )
        modelContext.insert(receipt)

        for item in items where item.isIncluded {
            // Create the ReceiptItem record
            let receiptItem = ReceiptItem(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                price: item.price
            )
            receiptItem.receipt = receipt
            modelContext.insert(receiptItem)

            // Add corresponding PantryItem
            let pantryItem = PantryItem(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                price: item.price,
                purchaseDate: purchaseDate
            )
            modelContext.insert(pantryItem)

            receiptItem.pantryItem = pantryItem
            receiptItem.isAddedToPantry = true
        }

        dismiss()
    }
}

// MARK: - EditableReceiptItemRow

private struct EditableReceiptItemRow: View {
    @Binding var item: EditableReceiptItem
    let commonUnits: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("Include", isOn: $item.isIncluded)
                .labelsHidden()
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                TextField("Item name", text: $item.name)
                    .font(.body)

                HStack(spacing: 8) {
                    TextField("Qty", value: $item.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 52)
                        .multilineTextAlignment(.trailing)

                    Picker("Unit", selection: $item.unit) {
                        ForEach(commonUnits, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()

                    Spacer()

                    if let price = item.price {
                        Text(price, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
        }
        .opacity(item.isIncluded ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.15), value: item.isIncluded)
    }
}

// MARK: - Preview

#Preview {
    let sampleOCR = """
    WHOLE FOODS MARKET
    02/27/2026
    Organic Whole Milk  3.99
    Free Range Eggs  1 DZ  5.99
    Sourdough Bread  4.50
    Bananas  0.8 LB  0.89
    SUBTOTAL  15.37
    TAX  1.23
    TOTAL  16.60
    """
    ReceiptReviewView(imageData: Data(), ocrText: sampleOCR)
        .modelContainer(for: [Receipt.self, ReceiptItem.self, PantryItem.self], inMemory: true)
}
