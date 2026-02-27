//
//  ModelsCategoryAndStorageLocationTests.swift
//  pantryTests
//

import Testing
import Foundation
import SwiftData
@testable import pantry

// MARK: - Category

struct CategoryTests {

    @Test func insert_categoryCanBeFetchedFromContext() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let category = Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop")
        context.insert(category)

        let results = try context.fetch(FetchDescriptor<Category>())
        #expect(results.count == 1)
        #expect(results[0].name == "Dairy")
        #expect(results[0].colorHex == "#5AC8FA")
        #expect(results[0].iconName == "drop")
    }

    @Test func delete_categoryIsRemovedFromContext() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let category = Category(name: "Snacks", colorHex: "#FF6482", iconName: "popcorn")
        context.insert(category)

        context.delete(category)

        let results = try context.fetch(FetchDescriptor<Category>())
        #expect(results.isEmpty)
    }

    @Test func insert_multipleCategories_allCanBeFetched() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        for default_ in Category.defaultCategories {
            context.insert(default_)
        }

        let results = try context.fetch(FetchDescriptor<Category>())
        #expect(results.count == Category.defaultCategories.count)
    }

    @Test func category_isDefaultFlag_isPreservedAfterInsert() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let userDefined = Category(name: "My Category", colorHex: "#FF0000", isDefault: false)
        let defaultCat = Category(name: "Produce", colorHex: "#34C759", isDefault: true)
        context.insert(userDefined)
        context.insert(defaultCat)

        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let defaults = try context.fetch(descriptor)
        #expect(defaults.count == 1)
        #expect(defaults[0].name == "Produce")
    }

    @Test func category_sortOrder_isPreservedAfterInsert() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let cat = Category(name: "Grains", colorHex: "#FF9500", sortOrder: 3)
        context.insert(cat)

        let results = try context.fetch(FetchDescriptor<Category>())
        #expect(results[0].sortOrder == 3)
    }
}

// MARK: - StorageLocation

struct StorageLocationTests {

    @Test func insert_locationCanBeFetchedFromContext() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let location = StorageLocation(name: "Refrigerator", iconName: "refrigerator")
        context.insert(location)

        let results = try context.fetch(FetchDescriptor<StorageLocation>())
        #expect(results.count == 1)
        #expect(results[0].name == "Refrigerator")
        #expect(results[0].iconName == "refrigerator")
    }

    @Test func delete_locationIsRemovedFromContext() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let location = StorageLocation(name: "Freezer", iconName: "snowflake")
        context.insert(location)

        context.delete(location)

        let results = try context.fetch(FetchDescriptor<StorageLocation>())
        #expect(results.isEmpty)
    }

    @Test func insert_allDefaultLocations_canBeFetched() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        for loc in StorageLocation.defaultLocations {
            context.insert(loc)
        }

        let results = try context.fetch(FetchDescriptor<StorageLocation>())
        #expect(results.count == StorageLocation.defaultLocations.count)
    }

    @Test func location_isDefaultFlag_isPreservedAfterInsert() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        context.insert(StorageLocation(name: "Pantry", iconName: "cabinet", isDefault: true))
        context.insert(StorageLocation(name: "Wine Cellar", iconName: "archivebox", isDefault: false))

        let descriptor = FetchDescriptor<StorageLocation>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let defaults = try context.fetch(descriptor)
        #expect(defaults.count == 1)
        #expect(defaults[0].name == "Pantry")
    }
}
