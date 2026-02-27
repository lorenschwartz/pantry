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
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Category.self, StorageLocation.self], inMemory: true)
}
