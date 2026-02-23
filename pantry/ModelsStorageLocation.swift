//
//  StorageLocation.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class StorageLocation {
    var id: UUID
    var name: String
    var iconName: String
    var isDefault: Bool
    var sortOrder: Int
    var parentLocationID: UUID?
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \PantryItem.location)
    var items: [PantryItem]?
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "archivebox",
        isDefault: Bool = false,
        sortOrder: Int = 0,
        parentLocationID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.parentLocationID = parentLocationID
    }
}

// MARK: - Default Locations
extension StorageLocation {
    static var defaultLocations: [StorageLocation] {
        [
            StorageLocation(name: "Pantry", iconName: "cabinet", isDefault: true, sortOrder: 0),
            StorageLocation(name: "Refrigerator", iconName: "refrigerator", isDefault: true, sortOrder: 1),
            StorageLocation(name: "Freezer", iconName: "snowflake", isDefault: true, sortOrder: 2),
            StorageLocation(name: "Counter", iconName: "square.grid.3x3", isDefault: true, sortOrder: 3),
            StorageLocation(name: "Garage", iconName: "house.and.flag", isDefault: true, sortOrder: 4)
        ]
    }
}
