//
//  ServicesEntityResolver.swift
//  pantry
//
//  Deterministic target resolution for assistant write operations.
//

import Foundation

enum PantryEntityResolution: Equatable {
    case unique(PantryItem)
    case ambiguous([PantryItem])
    case notFound

    static func == (lhs: PantryEntityResolution, rhs: PantryEntityResolution) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound):
            return true
        case let (.unique(a), .unique(b)):
            return a.id == b.id
        case let (.ambiguous(a), .ambiguous(b)):
            return a.map(\.id) == b.map(\.id)
        default:
            return false
        }
    }
}

enum EntityResolver {

    static func resolvePantryItem(named name: String, in items: [PantryItem]) -> PantryEntityResolution {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .notFound }

        let exact = items.filter {
            $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
        if exact.count == 1 { return .unique(exact[0]) }
        if exact.count > 1 { return .ambiguous(exact) }

        let fuzzy = items.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
            || trimmed.localizedCaseInsensitiveContains($0.name)
        }
        if fuzzy.count == 1 { return .unique(fuzzy[0]) }
        if fuzzy.count > 1 { return .ambiguous(fuzzy) }

        return .notFound
    }
}

