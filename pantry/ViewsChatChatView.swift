//
//  ChatView.swift
//  pantry
//
//  The main LLM assistant chat interface. Users interact with an AI that can
//  read and write pantry, recipe, and shopping-list data via tool use.
//

import SwiftUI
import SwiftData

// MARK: - Chat View

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query(sort: \ShoppingListItem.addedDate) private var shoppingItems: [ShoppingListItem]

    @State private var service = LLMService()
    @State private var inputText = ""
    @State private var showAPIKeySheet = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if service.hasAPIKey {
                chatInterface
            } else {
                APIKeySetupView(service: service)
            }
        }
        .navigationTitle("Pantry Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showAPIKeySheet) {
            APIKeySetupView(service: service)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Chat Interface

    private var chatInterface: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if service.chatMessages.isEmpty {
                        WelcomeMessageView(onSelect: sendSuggestion)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                    }
                    ForEach(service.chatMessages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    Color.clear
                        .frame(height: 8)
                        .id("bottom")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    ChatInputBar(
                        text: $inputText,
                        isLoading: service.isLoading,
                        isFocused: _isInputFocused,
                        onSend: sendMessage
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.bar)
                }
            }
            .onChange(of: service.chatMessages.count) {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: service.chatMessages.last?.content) {
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if service.hasAPIKey {
                Menu {
                    Button {
                        showAPIKeySheet = true
                    } label: {
                        Label("API Key Settings", systemImage: "key")
                    }
                    Divider()
                    Button(role: .destructive) {
                        service.clearConversation()
                    } label: {
                        Label("Clear Chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Send Message

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        isInputFocused = false
        Task {
            await service.sendMessage(text, context: modelContext)
        }
    }

    private func sendSuggestion(_ text: String) {
        inputText = text
        sendMessage()
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 48) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.isLoading {
                    LoadingBubbleView(activity: message.toolActivity)
                } else {
                    Text(message.content)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleColor)
                        .foregroundStyle(textColor)
                        .clipShape(bubbleShape)
                }
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant { Spacer(minLength: 48) }
        }
    }

    private var bubbleColor: Color {
        message.role == .user ? Color.accentColor : Color(.secondarySystemBackground)
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }

    private var bubbleShape: some Shape {
        RoundedRectangle(cornerRadius: 18)
    }
}

// MARK: - Loading Bubble

struct LoadingBubbleView: View {
    let activity: String?

    @State private var dotPhase = 0

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .frame(width: 7, height: 7)
                        .scaleEffect(dotPhase == index ? 1.2 : 0.8)
                        .opacity(dotPhase == index ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever().delay(Double(index) * 0.15),
                            value: dotPhase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if let activity {
                Text(activity)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .onAppear {
            dotPhase = 1
        }
    }
}

// MARK: - Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    @FocusState var isFocused: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit {
                    if !isLoading { onSend() }
                }

            Button(action: onSend) {
                Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Color.accentColor : Color.secondary)
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
    }

    private var canSend: Bool {
        !isLoading && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Welcome Message

struct WelcomeMessageView: View {
    let onSelect: (String) -> Void

    private let suggestions = [
        "What can I make for dinner tonight?",
        "Add 2 lbs of chicken to my pantry",
        "What's expiring soon?",
        "Create a recipe for pasta carbonara"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Pantry Assistant")
                    .font(.title2.bold())
                Text("I can help you manage your pantry, find recipes, and build shopping lists.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) {
                        onSelect(suggestion)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - API Key Setup View

struct APIKeySetupView: View {
    @Bindable var service: LLMService
    @State private var keyInput = ""
    @State private var isSecure = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if isSecure {
                            SecureField("sk-ant-...", text: $keyInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            TextField("sk-ant-...", text: $keyInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Button {
                            isSecure.toggle()
                        } label: {
                            Image(systemName: isSecure ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text("Your API key is stored locally on this device and never shared. Get a key at console.anthropic.com.")
                }

                Section {
                    Button("Save API Key") {
                        service.apiKey = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if service.hasAPIKey {
                    Section {
                        Button("Remove API Key", role: .destructive) {
                            service.apiKey = ""
                            keyInput = ""
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(service.hasAPIKey ? "API Key Settings" : "Set Up Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if service.hasAPIKey {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .onAppear {
                keyInput = service.apiKey
            }
        }
    }
}

// MARK: - Preview

#Preview("Chat - Empty") {
    ChatView()
        .modelContainer(for: [
            PantryItem.self, Category.self, StorageLocation.self,
            ShoppingListItem.self, Recipe.self, RecipeIngredient.self,
            RecipeInstruction.self, RecipeCategory.self, RecipeTag.self,
            RecipeCookingNote.self, RecipeCollection.self,
            Receipt.self, ReceiptItem.self, BarcodeMapping.self
        ], inMemory: true)
}

#Preview("Loading Bubble") {
    VStack {
        LoadingBubbleView(activity: "Checking your pantry…")
        LoadingBubbleView(activity: nil)
    }
    .padding()
}
