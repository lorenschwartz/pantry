//
//  ServicesCopilotPolicyServiceTests.swift
//  pantryTests
//

import Testing
@testable import pantry

struct CopilotPolicyServiceTests {

    @Test func evaluate_allowsReadOnlyTool() {
        let decision = CopilotPolicyService.evaluate(
            toolName: "get_pantry_items",
            input: [:]
        )
        #expect(decision == .allow)
    }

    @Test func evaluate_requiresConfirmation_forClearCheckedShoppingItems() {
        let decision = CopilotPolicyService.evaluate(
            toolName: "clear_checked_shopping_items",
            input: [:]
        )
        #expect(decision == .requireConfirmation)
    }

    @Test func evaluate_deniesDeleteAllPhrase_forRemovePantryItem() {
        let decision = CopilotPolicyService.evaluate(
            toolName: "remove_pantry_item",
            input: ["name": "all pantry items"]
        )
        #expect(decision == .deny)
    }

    @Test func evaluate_allowsSpecificName_forRemovePantryItem() {
        let decision = CopilotPolicyService.evaluate(
            toolName: "remove_pantry_item",
            input: ["name": "Whole Milk"]
        )
        #expect(decision == .allow)
    }
}

