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

    @State private var showLoadConfirmation = false
    @State private var showClearConfirmation = false
    @State private var statusMessage: String?

    private var hasExistingData: Bool { !pantryItems.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
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
}

#Preview {
    SettingsView()
        .modelContainer(for: [Category.self, StorageLocation.self], inMemory: true)
}
