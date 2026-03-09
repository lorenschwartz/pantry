//
//  ServicesToolInputValidatorTests.swift
//  pantryTests
//

import Testing
@testable import pantry

struct ToolInputValidatorTests {

    @Test func validate_rejectsUnknownField() {
        let result = ToolInputValidator.validate(
            toolName: "add_pantry_item",
            input: ["name": "Milk", "hacker_field": "x"]
        )
        #expect(result.isValid == false)
    }

    @Test func validate_rejectsMissingRequiredField() {
        let result = ToolInputValidator.validate(
            toolName: "add_pantry_item",
            input: ["quantity": 2]
        )
        #expect(result.isValid == false)
    }

    @Test func validate_rejectsWrongType() {
        let result = ToolInputValidator.validate(
            toolName: "add_pantry_item",
            input: ["name": "Milk", "quantity": "two"]
        )
        #expect(result.isValid == false)
    }

    @Test func validate_rejectsUnexpectedInput_forEmptySchemaTool() {
        let result = ToolInputValidator.validate(
            toolName: "get_pantry_items",
            input: ["name": "should-not-exist"]
        )
        #expect(result.isValid == false)
    }

    @Test func validate_acceptsValidPayload() {
        let result = ToolInputValidator.validate(
            toolName: "add_pantry_item",
            input: ["name": "Milk", "quantity": 2.0, "unit": "gallon"]
        )
        #expect(result.isValid == true)
    }

    @Test func validate_rejectsInvalidDateFormat() {
        let result = ToolInputValidator.validate(
            toolName: "update_pantry_item",
            input: ["name": "Milk", "expiration_date": "03/12/2026"]
        )
        #expect(result.isValid == false)
    }
}

