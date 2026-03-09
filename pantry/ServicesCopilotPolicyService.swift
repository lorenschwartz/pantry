//
//  ServicesCopilotPolicyService.swift
//  pantry
//
//  Central policy gate for LLM tool calls.
//

import Foundation

enum CopilotPolicyDecision: Equatable {
    case allow
    case requireConfirmation
    case deny
}

enum CopilotPolicyService {

    /// Evaluates whether a validated tool call can execute immediately.
    static func evaluate(toolName: String, input: [String: Any]) -> CopilotPolicyDecision {
        switch toolName {
        case "clear_checked_shopping_items":
            // Bulk-destructive operation; require explicit user approval.
            return .requireConfirmation

        case "remove_pantry_item":
            guard let raw = input["name"] as? String else { return .deny }
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if name.isEmpty { return .deny }
            if looksLikeDeleteAllRequest(name) { return .deny }
            return .allow

        default:
            return .allow
        }
    }

    private static func looksLikeDeleteAllRequest(_ text: String) -> Bool {
        let blockedPhrases = [
            "all pantry items",
            "delete everything",
            "remove everything",
            "entire pantry",
            "all items",
            "everything"
        ]
        return blockedPhrases.contains { text.contains($0) }
    }
}

