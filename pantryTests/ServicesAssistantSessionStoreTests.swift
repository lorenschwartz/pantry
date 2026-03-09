//
//  ServicesAssistantSessionStoreTests.swift
//  pantryTests
//

import Testing
@testable import pantry

@MainActor
struct AssistantSessionStoreTests {

    @Test func clearConversation_isOnlyPathThatEmptiesSharedThread() {
        let store = AssistantSessionStore()
        store.service.chatMessages = [
            ChatMessage(role: .user, content: "hello"),
            ChatMessage(role: .assistant, content: "hi")
        ]

        #expect(store.service.chatMessages.count == 2)

        store.clearConversation()

        #expect(store.service.chatMessages.isEmpty)
    }

    @Test func sharedStore_referenceRetainsMessagesAcrossConsumers() {
        let store = AssistantSessionStore()
        store.service.chatMessages = [ChatMessage(role: .user, content: "almonds")]

        let firstConsumer = store
        let secondConsumer = store

        #expect(firstConsumer.service.chatMessages.count == 1)
        #expect(secondConsumer.service.chatMessages.count == 1)
    }
}

