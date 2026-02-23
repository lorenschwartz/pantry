//
//  Category.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var isDefault: Bool
    var sortOrder: Int
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \PantryItem.category)
    var items: [PantryItem]?
    
    // Computed property for color
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        iconName: String = "tag",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}

// MARK: - Default Categories
extension Category {
    static var defaultCategories: [Category] {
        [
            Category(name: "Produce", colorHex: "#34C759", iconName: "leaf", isDefault: true, sortOrder: 0),
            Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop", isDefault: true, sortOrder: 1),
            Category(name: "Proteins", colorHex: "#FF3B30", iconName: "flame", isDefault: true, sortOrder: 2),
            Category(name: "Grains", colorHex: "#FF9500", iconName: "square.grid.2x2", isDefault: true, sortOrder: 3),
            Category(name: "Spices", colorHex: "#AF52DE", iconName: "sparkles", isDefault: true, sortOrder: 4),
            Category(name: "Condiments", colorHex: "#FFCC00", iconName: "drop.triangle", isDefault: true, sortOrder: 5),
            Category(name: "Beverages", colorHex: "#00C7BE", iconName: "cup.and.saucer", isDefault: true, sortOrder: 6),
            Category(name: "Snacks", colorHex: "#FF6482", iconName: "popcorn", isDefault: true, sortOrder: 7),
            Category(name: "Frozen", colorHex: "#64D2FF", iconName: "snowflake", isDefault: true, sortOrder: 8),
            Category(name: "Canned", colorHex: "#BF5AF2", iconName: "cylinder", isDefault: true, sortOrder: 9),
            Category(name: "Baking", colorHex: "#FFD60A", iconName: "birthday.cake", isDefault: true, sortOrder: 10)
        ]
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
