//
//  ReceiptItemRow.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-03-03.
//

import SwiftUI

// MARK: - Review Row (used in ReceiptReviewView — shows a ParsedReceiptLine)

/// Displays a single parsed receipt line during the review step.
/// The checkbox lets the user include or exclude the item before saving.
struct ParsedReceiptLineRow: View {
    @Binding var line: ParsedReceiptLine

    var body: some View {
        HStack(spacing: 12) {
            // Selection toggle
            Button {
                line.isSelected.toggle()
            } label: {
                Image(systemName: line.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(line.isSelected ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            // Name
            Text(line.name)
                .font(.body)
                .foregroundStyle(line.isSelected ? .primary : .secondary)
                .strikethrough(!line.isSelected, color: .secondary)

            Spacer()

            // Price
            if let price = line.price {
                Text("$\(price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundStyle(line.isSelected ? .primary : .secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { line.isSelected.toggle() }
    }
}

// MARK: - Detail Row (used in ReceiptDetailView — shows a saved ReceiptItem)

/// Displays a single saved `ReceiptItem` in the receipt detail view.
/// Shows an "Add to Pantry" button when the item has not yet been added.
struct ReceiptItemDetailRow: View {
    let item: ReceiptItem
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Pantry status indicator
            Image(systemName: item.isAddedToPantry ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isAddedToPantry ? Color.green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                if item.quantity != 1 || item.unit != "item" {
                    Text("\(item.quantity.formatted()) \(item.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let price = item.price {
                Text("$\(price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if !item.isAddedToPantry {
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}
