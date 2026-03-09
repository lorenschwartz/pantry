//
//  ServicesEntityResolverTests.swift
//  pantryTests
//

import Testing
@testable import pantry

struct EntityResolverTests {

    @Test func resolvePantryItem_returnsUnique_whenOneItemMatches() {
        let items = [
            PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon"),
            PantryItem(name: "Eggs", quantity: 12, unit: "count")
        ]

        let result = EntityResolver.resolvePantryItem(named: "milk", in: items)
        switch result {
        case .unique(let item):
            #expect(item.name == "Whole Milk")
        default:
            Issue.record("Expected unique result")
        }
    }

    @Test func resolvePantryItem_returnsAmbiguous_whenMultipleItemsMatch() {
        let items = [
            PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon"),
            PantryItem(name: "Almond Milk", quantity: 1, unit: "carton")
        ]

        let result = EntityResolver.resolvePantryItem(named: "milk", in: items)
        switch result {
        case .ambiguous(let matches):
            #expect(matches.count == 2)
        default:
            Issue.record("Expected ambiguous result")
        }
    }

    @Test func resolvePantryItem_returnsNotFound_whenNoItemMatches() {
        let items = [
            PantryItem(name: "Eggs", quantity: 12, unit: "count")
        ]

        let result = EntityResolver.resolvePantryItem(named: "milk", in: items)
        #expect(result == .notFound)
    }
}

