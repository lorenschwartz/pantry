//
//  Item.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
