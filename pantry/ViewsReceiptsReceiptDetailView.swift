//
//  ReceiptDetailView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import SwiftData

/// Displays the full details of a saved receipt: metadata, line items, and
/// the receipt image (if available).
struct ReceiptDetailView: View {
    @Bindable var receipt: Receipt
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            infoSection
            if let items = receipt.items, !items.isEmpty {
                itemsSection(items)
            }
            if let imageData = receipt.imageData, let ui = UIImage(data: imageData) {
                imageSection(ui)
            }
        }
        .navigationTitle(receipt.storeName ?? "Receipt")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Sections

    private var infoSection: some View {
        Section("Details") {
            if let store = receipt.storeName {
                LabeledContent("Store", value: store)
            }
            LabeledContent(
                "Date",
                value: receipt.purchaseDate.formatted(date: .long, time: .omitted))
            if let total = receipt.totalAmount {
                LabeledContent("Total") {
                    Text(total, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                }
            }
            LabeledContent("Items", value: "\(receipt.itemCount)")
        }
    }

    private func itemsSection(_ items: [ReceiptItem]) -> some View {
        Section("Items") {
            ForEach(items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.body)
                        Text("\(item.quantity.formatted()) \(item.unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let price = item.price {
                            Text(price, format: .currency(code: "USD"))
                                .font(.subheadline)
                        }
                        if item.isAddedToPantry {
                            Label("In pantry", systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                                .labelStyle(.iconOnly)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func imageSection(_ image: UIImage) -> some View {
        Section("Receipt Image") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Receipt.self, ReceiptItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let receipt = Receipt(storeName: "Whole Foods", purchaseDate: Date(), totalAmount: 16.60)
    ctx.insert(receipt)

    let items: [(String, Double, Double)] = [
        ("Organic Whole Milk", 3.99, 1.0),
        ("Free Range Eggs", 5.99, 1.0),
        ("Sourdough Bread", 4.50, 1.0),
        ("Bananas", 0.89, 0.8)
    ]
    for (name, price, qty) in items {
        let ri = ReceiptItem(name: name, quantity: qty, price: price)
        ri.receipt = receipt
        ri.isAddedToPantry = true
        ctx.insert(ri)
    }

    return NavigationStack {
        ReceiptDetailView(receipt: receipt)
    }
    .modelContainer(container)
}
