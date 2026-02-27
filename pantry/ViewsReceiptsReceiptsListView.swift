//
//  ReceiptsListView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct ReceiptsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.purchaseDate, order: .reverse) private var receipts: [Receipt]

    @State private var showingScanner = false
    @State private var pendingImageData: Data?
    @State private var pendingOCRText: String?
    @State private var showingReview = false

    var body: some View {
        NavigationStack {
            Group {
                if receipts.isEmpty {
                    emptyState
                } else {
                    receiptList
                }
            }
            .navigationTitle("Receipts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "doc.text.viewfinder")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                ReceiptScannerView { imageData, ocrText in
                    pendingImageData = imageData
                    pendingOCRText = ocrText
                    showingReview = true
                }
            }
            .sheet(isPresented: $showingReview) {
                if let imageData = pendingImageData, let ocrText = pendingOCRText {
                    ReceiptReviewView(imageData: imageData, ocrText: ocrText)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Receipts", systemImage: "doc.text")
        } description: {
            Text("Scan a grocery receipt to automatically add items to your pantry and track purchase history.")
        } actions: {
            Button("Scan Receipt") {
                showingScanner = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Receipt list

    private var receiptList: some View {
        List {
            ForEach(receipts) { receipt in
                NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                    ReceiptRowView(receipt: receipt)
                }
            }
            .onDelete(perform: deleteReceipts)
        }
    }

    private func deleteReceipts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(receipts[index])
        }
    }
}

// MARK: - ReceiptRowView

private struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.storeName ?? "Unknown Store")
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(receipt.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if receipt.itemCount > 0 {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("\(receipt.itemCount) item\(receipt.itemCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if let total = receipt.totalAmount {
                Text(total, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("With receipts") {
    let container = try! ModelContainer(
        for: Receipt.self, ReceiptItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let stores: [(String, Double, Int)] = [
        ("Whole Foods", 45.32, 8),
        ("Target", 28.10, 5),
        ("Trader Joe's", 62.75, 12)
    ]
    for (i, (store, total, count)) in stores.enumerated() {
        let receipt = Receipt(
            storeName: store,
            purchaseDate: Calendar.current.date(byAdding: .day, value: -i * 7, to: Date())!,
            totalAmount: total
        )
        ctx.insert(receipt)
        for j in 0..<count {
            let item = ReceiptItem(name: "Item \(j + 1)", quantity: 1, price: total / Double(count))
            item.receipt = receipt
            ctx.insert(item)
        }
    }

    return ReceiptsListView().modelContainer(container)
}

#Preview("Empty") {
    ReceiptsListView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
