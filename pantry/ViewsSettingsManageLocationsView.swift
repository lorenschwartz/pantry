//
//  ManageLocationsView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import SwiftData

// MARK: - Manage Locations List

struct ManageLocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]

    @State private var showingAddSheet = false
    @State private var editingLocation: StorageLocation?

    var body: some View {
        List {
            ForEach(locations) { location in
                Button {
                    editingLocation = location
                } label: {
                    LocationRow(location: location)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteLocations)
        }
        .navigationTitle("Storage Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditLocationView()
        }
        .sheet(item: $editingLocation) { location in
            AddEditLocationView(location: location)
        }
        .overlay {
            if locations.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "archivebox",
                    description: Text("Tap + to create a storage location.")
                )
            }
        }
    }

    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(locations[index])
        }
    }
}

// MARK: - Location Row

private struct LocationRow: View {
    let location: StorageLocation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: location.iconName)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())

            Text(location.name)

            Spacer()

            if location.isDefault {
                Text("Default")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Add / Edit Location Sheet

struct AddEditLocationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var location: StorageLocation?

    @State private var name = ""
    @State private var selectedIcon = "archivebox"

    var isEditing: Bool { location != nil }

    private let iconOptions: [String] = [
        "cabinet", "refrigerator", "snowflake", "archivebox", "house.and.flag",
        "square.grid.3x3", "tray.2", "tray", "door.left.hand.open", "building.2",
        "cart", "bag", "shippingbox", "books.vertical",
        "folder", "house", "star", "tag", "bookmark",
        "basket", "box.truck", "storefront", "warehouse"
    ]

    init(location: StorageLocation? = nil) {
        self.location = location
        if let location {
            _name = State(initialValue: location.name)
            _selectedIcon = State(initialValue: location.iconName)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Location Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                    .background(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .foregroundStyle(.blue)
                            .frame(width: 34, height: 34)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Circle())

                        Text(name.isEmpty ? "Location Name" : name)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Location" : "New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let location {
            location.name = trimmedName
            location.iconName = selectedIcon
        } else {
            let newLocation = StorageLocation(
                name: trimmedName,
                iconName: selectedIcon
            )
            modelContext.insert(newLocation)
        }
        dismiss()
    }
}

// MARK: - Previews

#Preview("Manage Locations") {
    NavigationStack {
        ManageLocationsView()
    }
    .modelContainer(for: [StorageLocation.self, PantryItem.self], inMemory: true)
}

#Preview("Add Location") {
    AddEditLocationView()
        .modelContainer(for: StorageLocation.self, inMemory: true)
}

#Preview("Edit Location") {
    let container = try! ModelContainer(
        for: StorageLocation.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let location = StorageLocation.defaultLocations[0]
    container.mainContext.insert(location)
    return AddEditLocationView(location: location)
        .modelContainer(container)
}
