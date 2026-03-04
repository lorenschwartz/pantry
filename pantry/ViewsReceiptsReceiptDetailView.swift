//
//  ReceiptDetailView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-03-03.
//

import SwiftUI
import SwiftData

/// Shows a saved `Receipt` and lets the user add its items to the pantry.
///
/// Accessible via:
/// - `ReceiptsListView` → `NavigationLink` from the receipt list
/// - `ReceiptReviewView` → auto-pushed immediately after saving
struct ReceiptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var receipt: Receipt

    private var unadded: [ReceiptItem] {
        receipt.items?.filter { !$0.isAddedToPantry } ?? []
    }

    var body: some View {
        Form {
            // MARK: - Summary section
            Section("Summary") {
                if let storeName = receipt.storeName {
                    LabeledContent("Store", value: storeName)
                }
                LabeledContent("Date", value: receipt.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                if let total = receipt.totalAmount {
                    LabeledContent("Total", value: String(format: "$%.2f", total))
                }
                LabeledContent("Items", value: "\(receipt.itemCount)")
            }

            // MARK: - Items section
            if let items = receipt.items, !items.isEmpty {
                Section {
                    ForEach(items) { item in
                        ReceiptItemDetailRow(item: item) {
                            ReceiptScanService.addReceiptItemToPantry(
                                item,
                                receipt: receipt,
                                context: modelContext
                            )
                        }
                    }
                } header: {
                    HStack {
                        Text("Items")
                        Spacer()
                        if !unadded.isEmpty {
                            Button("Add All to Pantry") {
                                ReceiptScanService.addAllItemsToPantry(
                                    receipt: receipt,
                                    context: modelContext
                                )
                            }
                            .font(.caption)
                            .textCase(nil)
                        }
                    }
                }
            }

            // MARK: - Receipt image section
            if let imageData = receipt.imageData, let uiImage = UIImage(data: imageData) {
                Section("Receipt Image") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(receipt.storeName ?? "Receipt")
        .navigationBarTitleDisplayMode(.inline)
    }
}
