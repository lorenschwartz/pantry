//
//  ReceiptReviewView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-03-03.
//

import SwiftUI
import SwiftData

/// Presents the OCR-parsed receipt for user review before saving to SwiftData.
///
/// The user can:
/// - Edit the store name, date, and total amount
/// - Toggle individual line items on/off (unselected items are not saved)
/// - Delete line items by swiping
/// - Select / deselect all items at once
/// - Save the reviewed receipt, which navigates to `ReceiptDetailView`
struct ReceiptReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parsedReceipt: ParsedReceipt
    let sourceImage: UIImage?
    /// Called with the saved `Receipt` so the caller can push to the detail view.
    var onSave: (Receipt) -> Void

    @State private var storeName: String
    @State private var purchaseDate: Date
    @State private var totalAmount: String
    @State private var lines: [ParsedReceiptLine]

    init(
        parsedReceipt: ParsedReceipt,
        sourceImage: UIImage?,
        onSave: @escaping (Receipt) -> Void
    ) {
        self.parsedReceipt = parsedReceipt
        self.sourceImage = sourceImage
        self.onSave = onSave
        _storeName    = State(initialValue: parsedReceipt.storeName ?? "")
        _purchaseDate = State(initialValue: parsedReceipt.purchaseDate ?? Date())
        _totalAmount  = State(initialValue: parsedReceipt.totalAmount.map {
            String(format: "%.2f", $0)
        } ?? "")
        _lines = State(initialValue: parsedReceipt.lines)
    }

    private var allSelected: Bool { lines.allSatisfy { $0.isSelected } }
    private var selectedCount: Int { lines.filter { $0.isSelected }.count }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Header section
                Section("Receipt Details") {
                    LabeledContent("Store") {
                        TextField("Store name", text: $storeName)
                            .multilineTextAlignment(.trailing)
                    }
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                    LabeledContent("Total") {
                        TextField("0.00", text: $totalAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // MARK: Line items section
                Section {
                    ForEach($lines) { $line in
                        ParsedReceiptLineRow(line: $line)
                    }
                    .onDelete { indexSet in
                        lines.remove(atOffsets: indexSet)
                    }
                } header: {
                    HStack {
                        Text("Items (\(selectedCount) selected)")
                        Spacer()
                        Button(allSelected ? "Deselect All" : "Select All") {
                            let newValue = !allSelected
                            for index in lines.indices {
                                lines[index].isSelected = newValue
                            }
                        }
                        .font(.caption)
                        .textCase(nil)
                    }
                } footer: {
                    if lines.isEmpty {
                        Text("No items were detected. You can add them manually after saving.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Review Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndProceed() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveAndProceed() {
        // Build a corrected ParsedReceipt from the edited fields
        let corrected = ParsedReceipt(
            storeName: storeName.isEmpty ? nil : storeName,
            purchaseDate: purchaseDate,
            totalAmount: Double(totalAmount),
            lines: lines,
            rawOCRText: parsedReceipt.rawOCRText
        )

        let receipt = ReceiptScanService.saveReceipt(
            corrected,
            image: sourceImage,
            context: modelContext
        )
        onSave(receipt)
        dismiss()
    }
}
