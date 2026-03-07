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

    // MARK: - Scan-flow state

    /// Controls the "Camera vs Photos" source picker dialog.
    @Binding var showingSourcePicker: Bool
    /// Controls `DocumentScannerView` full-screen cover.
    @State private var isScanning = false
    /// Controls `PhotoPickerView` sheet.
    @State private var isPickingPhoto = false
    /// True while Vision OCR is running.
    @State private var isProcessing = false
    /// The image that was captured / picked — passed through to the review sheet.
    @State private var capturedImage: UIImage?
    /// The parsed OCR result — non-nil atomically presents the review sheet via `.sheet(item:)`.
    @State private var parsedReceipt: ParsedReceipt?
    /// After a review is saved, push to detail view immediately.
    @State private var savedReceipt: Receipt?
    /// Non-nil shows the OCR error alert.
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                receiptList
                if isProcessing { processingOverlay }
            }
            .navigationTitle("Receipts")
            // Source picker
            .confirmationDialog("Add Receipt", isPresented: $showingSourcePicker) {
                Button("Scan Document") { isScanning = true }
                Button("Choose from Photos") { isPickingPhoto = true }
                Button("Cancel", role: .cancel) {}
            }
            // Document camera (full-screen)
            .fullScreenCover(isPresented: $isScanning) {
                DocumentScannerView(
                    onScan: { images in
                        isScanning = false
                        guard let first = images.first else { return }
                        capturedImage = first
                        runOCR(on: first)
                    },
                    onCancel: { isScanning = false },
                    onError: { error in
                        isScanning = false
                        errorMessage = error.localizedDescription
                    }
                )
                .ignoresSafeArea()
            }
            // Photo library picker
            .sheet(isPresented: $isPickingPhoto) {
                PhotoPickerView(
                    onPick: { image in
                        isPickingPhoto = false
                        capturedImage = image
                        runOCR(on: image)
                    },
                    onCancel: { isPickingPhoto = false }
                )
            }
            // Review sheet — uses .sheet(item:) so presentation and data are atomically coupled
            .sheet(item: $parsedReceipt) { parsed in
                ReceiptReviewView(
                    parsedReceipt: parsed,
                    sourceImage: capturedImage,
                    onSave: { receipt in
                        savedReceipt = receipt
                    }
                )
            }
            // Navigate to detail view immediately after saving a review
            .navigationDestination(item: $savedReceipt) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            // OCR error alert
            .alert("Scanning Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let msg = errorMessage { Text(msg) }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var receiptList: some View {
        if receipts.isEmpty {
            ContentUnavailableView(
                "No Receipts",
                systemImage: "doc.text.viewfinder",
                description: Text("Tap the + button below to scan or import a receipt")
            )
        } else {
            List {
                ForEach(receipts) { receipt in
                    NavigationLink {
                        ReceiptDetailView(receipt: receipt)
                    } label: {
                        ReceiptListRow(receipt: receipt)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteReceipt(receipt)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text("Reading receipt…")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(Color(.systemGray3).opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Actions

    private func runOCR(on image: UIImage) {
        isProcessing = true
        ReceiptScanService.recognizeText(in: image) { result in
            isProcessing = false
            switch result {
            case .success(let text):
                // Setting parsedReceipt atomically triggers .sheet(item:)
                parsedReceipt = ReceiptScanService.parse(ocrText: text)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteReceipt(_ receipt: Receipt) {
        withAnimation {
            modelContext.delete(receipt)
            try? modelContext.save()
        }
    }
}

// MARK: - Receipt List Row

private struct ReceiptListRow: View {
    let receipt: Receipt

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(receipt.storeName ?? "Unknown Store")
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(receipt.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if receipt.itemCount > 0 {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("\(receipt.itemCount) item\(receipt.itemCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let total = receipt.totalAmount {
                Text("$\(total, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReceiptsListView(showingSourcePicker: .constant(false))
        .modelContainer(for: [Receipt.self, ReceiptItem.self, PantryItem.self], inMemory: true)
}
