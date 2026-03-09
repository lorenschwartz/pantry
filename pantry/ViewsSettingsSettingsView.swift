//
//  SettingsView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var locations: [StorageLocation]
    @Query private var pantryItems: [PantryItem]
    private let keychainService = KeychainService()

    @State private var showLoadConfirmation = false
    @State private var showClearConfirmation = false
    @State private var statusMessage: String?
    @State private var apiKeyInput = ""
    @State private var isAPIKeySecure = true

    private var hasExistingData: Bool { !pantryItems.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if isAPIKeySecure {
                            SecureField("sk-ant-...", text: $apiKeyInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            TextField("sk-ant-...", text: $apiKeyInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        Button {
                            isAPIKeySecure.toggle()
                        } label: {
                            Image(systemName: isAPIKeySecure ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Save API Key") {
                        saveAssistantAPIKey()
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if !apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("Remove API Key", role: .destructive) {
                            removeAssistantAPIKey()
                        }
                    }
                } header: {
                    Text("Assistant")
                } footer: {
                    Text("Your Anthropic API key is stored locally in Keychain and used by the Assistant.")
                }

                Section("Inventory") {
                    NavigationLink {
                        ManageCategoriesView()
                    } label: {
                        HStack {
                            Label("Categories", systemImage: "tag")
                            Spacer()
                            Text("\(categories.count)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        ManageLocationsView()
                    } label: {
                        HStack {
                            Label("Storage Locations", systemImage: "archivebox")
                            Spacer()
                            Text("\(locations.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        if hasExistingData {
                            showLoadConfirmation = true
                        } else {
                            insertSampleData()
                        }
                    } label: {
                        Label("Load Sample Data", systemImage: "tray.and.arrow.down")
                    }

                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                    .disabled(pantryItems.isEmpty && categories.isEmpty && locations.isEmpty)
                } header: {
                    Text("Developer")
                } footer: {
                    if let msg = statusMessage {
                        Text(msg)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Load sample data to explore every feature. Clear All Data permanently removes everything from the store.")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS / iPadOS 17+")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    // SeedDataButton owns its own @Environment and @State so they
                    // are not stored on SettingsView itself — this avoids an
                    // OpaqueExistentialBox crash when TabView instantiates
                    // SettingsView as a temporary value during its first layout pass.
                    SeedDataButton()
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Populates every screen with realistic sample items, recipes, shopping list entries, and receipts for UI testing.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Data Already Exists",
                isPresented: $showLoadConfirmation,
                titleVisibility: .visible
            ) {
                Button("Add Sample Data Anyway") { insertSampleData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your pantry already has items. Adding sample data will create additional entries alongside your existing data.")
            }
            .alert("Clear All Data?", isPresented: $showClearConfirmation) {
                Button("Delete Everything", role: .destructive) { clearAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all pantry items, recipes, shopping lists, receipts, categories, and locations. This cannot be undone.")
            }
            .onAppear {
                apiKeyInput = keychainService.loadAPIKey()
            }
        }
    }

    // MARK: - Actions

    private func insertSampleData() {
        let n = SampleDataService.loadSampleData(into: modelContext)
        statusMessage = "Loaded \(n) records."
        clearStatusAfterDelay()
    }

    private func clearAllData() {
        SampleDataService.clearAllData(from: modelContext)
        statusMessage = "All data cleared."
        clearStatusAfterDelay()
    }

    private func clearStatusAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            statusMessage = nil
        }
    }

    private func saveAssistantAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        keychainService.saveAPIKey(trimmed)
        apiKeyInput = trimmed
        statusMessage = "Assistant API key saved."
        clearStatusAfterDelay()
    }

    private func removeAssistantAPIKey() {
        keychainService.saveAPIKey("")
        apiKeyInput = ""
        statusMessage = "Assistant API key removed."
        clearStatusAfterDelay()
    }
}

// MARK: - Seed Data Button

/// Isolated child view that holds all seed-related state and environment
/// access, keeping them off the parent SettingsView struct.
private struct SeedDataButton: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    @State private var showSeedConfirm = false
    @State private var showSeedSuccess = false
    @State private var showSeedError = false
    @State private var seedErrorMessage = ""

    var body: some View {
        Button {
            if categories.isEmpty {
                runSeed()
            } else {
                showSeedConfirm = true
            }
        } label: {
            Label("Seed Sample Data", systemImage: "wand.and.stars")
        }
        .confirmationDialog(
            "Sample data already exists",
            isPresented: $showSeedConfirm,
            titleVisibility: .visible
        ) {
            Button("Add More Sample Data") { runSeed() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will append another full set of sample data to the existing store.")
        }
        .alert("Sample Data Added", isPresented: $showSeedSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All screens have been populated with sample data.")
        }
        .alert("Seed Failed", isPresented: $showSeedError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(seedErrorMessage)
        }
    }

    private func runSeed() {
        do {
            try SeedDataService.seed(context: modelContext)
            showSeedSuccess = true
        } catch {
            seedErrorMessage = error.localizedDescription
            showSeedError = true
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Category.self, StorageLocation.self], inMemory: true)
}
