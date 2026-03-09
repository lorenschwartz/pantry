//
//  ServicesToolInputValidator.swift
//  pantry
//
//  Strict schema validation for assistant tool payloads.
//

import Foundation

struct ToolValidationResult {
    let isValid: Bool
    let error: String?

    static var valid: ToolValidationResult {
        ToolValidationResult(isValid: true, error: nil)
    }

    static func invalid(_ message: String) -> ToolValidationResult {
        ToolValidationResult(isValid: false, error: message)
    }
}

enum ToolInputValidator {

    private struct ToolSchema {
        let required: Set<String>
        let validators: [String: (Any) -> Bool]
    }

    static func validate(toolName: String, input: [String: Any]) -> ToolValidationResult {
        guard let schema = schemas[toolName] else {
            return .invalid("Unknown tool schema: \(toolName)")
        }

        for requiredField in schema.required {
            if input[requiredField] == nil {
                return .invalid("Missing required field '\(requiredField)'")
            }
        }

        for (key, value) in input {
            guard let validator = schema.validators[key] else {
                return .invalid("Unknown field '\(key)' for tool \(toolName)")
            }
            guard validator(value) else {
                return .invalid("Invalid value for field '\(key)'")
            }
        }

        return .valid
    }

    // MARK: - Schemas

    private static let schemas: [String: ToolSchema] = [
        "get_pantry_items": ToolSchema(required: [], validators: [:]),
        "get_recipes": ToolSchema(required: [], validators: [:]),
        "get_shopping_list": ToolSchema(required: [], validators: [:]),
        "get_expiring_items": ToolSchema(required: [], validators: [:]),
        "suggest_recipes": ToolSchema(required: [], validators: [:]),
        "clear_checked_shopping_items": ToolSchema(required: [], validators: [:]),

        "add_pantry_item": ToolSchema(
            required: ["name"],
            validators: [
                "name": isNonEmptyString,
                "quantity": isNumber,
                "unit": isString,
                "brand": isString,
                "expiration_date": isISODateString,
                "notes": isString
            ]
        ),

        "update_pantry_item": ToolSchema(
            required: ["name"],
            validators: [
                "name": isNonEmptyString,
                "quantity": isNumber,
                "unit": isString,
                "brand": isString,
                "expiration_date": isISODateString,
                "notes": isString
            ]
        ),

        "remove_pantry_item": ToolSchema(
            required: ["name"],
            validators: ["name": isNonEmptyString]
        ),

        "get_recipe_details": ToolSchema(
            required: ["name"],
            validators: ["name": isNonEmptyString]
        ),

        "create_recipe": ToolSchema(
            required: ["name"],
            validators: [
                "name": isNonEmptyString,
                "description": isString,
                "prep_time": isInteger,
                "cook_time": isInteger,
                "servings": isInteger,
                "difficulty": isString,
                "notes": isString,
                "ingredients": isArrayOfDictionaries,
                "instructions": isStringArrayOrArrayOfDictionaries
            ]
        ),

        "add_to_shopping_list": ToolSchema(
            required: ["name"],
            validators: [
                "name": isNonEmptyString,
                "quantity": isNumber,
                "unit": isString,
                "notes": isString,
                "priority": isInteger
            ]
        ),

        "check_shopping_item": ToolSchema(
            required: ["name"],
            validators: [
                "name": isNonEmptyString,
                "checked": isBool
            ]
        )
    ]

    // MARK: - Validators

    private static let isString: (Any) -> Bool = { $0 is String }
    private static let isBool: (Any) -> Bool = { $0 is Bool }
    private static let isNumber: (Any) -> Bool = { $0 is Int || $0 is Double }
    private static let isInteger: (Any) -> Bool = { $0 is Int }
    private static let isArrayOfDictionaries: (Any) -> Bool = { value in
        guard let array = value as? [Any] else { return false }
        return array.allSatisfy { $0 is [String: Any] }
    }
    private static let isStringArrayOrArrayOfDictionaries: (Any) -> Bool = { value in
        if let strings = value as? [Any], strings.allSatisfy({ $0 is String }) {
            return true
        }
        if let dicts = value as? [Any], dicts.allSatisfy({ $0 is [String: Any] }) {
            return true
        }
        return false
    }
    private static let isNonEmptyString: (Any) -> Bool = { value in
        guard let string = value as? String else { return false }
        return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private static let isISODateString: (Any) -> Bool = { value in
        guard let string = value as? String else { return false }
        return parseISODate(string) != nil
    }

    private static func parseISODate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: value)
    }
}

