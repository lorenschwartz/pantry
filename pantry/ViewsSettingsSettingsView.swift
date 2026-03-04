//
//  SettingsView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var categories: [Category]
    @Query private var locations: [StorageLocation]

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
        }
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
