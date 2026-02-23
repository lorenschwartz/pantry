//
//  PantryItemRow.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI

struct PantryItemRow: View {
    let item: PantryItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Image or icon
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.category?.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                    Image(systemName: item.category?.iconName ?? "cube.box")
                        .foregroundStyle(item.category?.color ?? .gray)
                        .font(.title3)
                }
                .frame(width: 50, height: 50)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 8) {
                    // Quantity
                    Label("\(item.quantity.formatted()) \(item.unit)", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Location
                    if let location = item.location {
                        Label(location.name, systemImage: location.iconName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Expiration info
                if let daysUntil = item.daysUntilExpiration {
                    HStack(spacing: 4) {
                        Image(systemName: item.isExpired ? "exclamationmark.triangle.fill" : item.isExpiringSoon ? "clock.fill" : "calendar")
                        Text(expirationText(daysUntil: daysUntil))
                    }
                    .font(.caption)
                    .foregroundStyle(item.isExpired ? .red : item.isExpiringSoon ? .orange : .secondary)
                }
            }
            
            Spacer()
            
            // Status indicators
            VStack(alignment: .trailing, spacing: 4) {
                if let price = item.price {
                    Text("$\(price, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if item.isLowStock {
                    Label("Low", systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func expirationText(daysUntil: Int) -> String {
        if item.isExpired {
            return "Expired \(abs(daysUntil))d ago"
        } else if daysUntil == 0 {
            return "Expires today"
        } else if daysUntil == 1 {
            return "Expires tomorrow"
        } else {
            return "Expires in \(daysUntil)d"
        }
    }
}

#Preview {
    List {
        PantryItemRow(item: PantryItem.sampleItems[0])
        PantryItemRow(item: PantryItem.sampleItems[1])
        PantryItemRow(item: PantryItem.sampleItems[2])
    }
}
