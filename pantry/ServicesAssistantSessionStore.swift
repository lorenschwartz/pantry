//
//  ServicesAssistantSessionStore.swift
//  pantry
//

import Foundation
import SwiftData

@Observable
@MainActor
final class AssistantSessionStore {
    let service: LLMService
    var draftMessage = ""

    init(service: LLMService? = nil) {
        self.service = service ?? LLMService()
    }

    func sendDraft(context: ModelContext) async {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draftMessage = ""
        await service.sendMessage(trimmed, context: context)
    }

    func clearConversation() {
        service.clearConversation()
    }
}
