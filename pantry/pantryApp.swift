//
//  pantryApp.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-21.
//

import SwiftUI
import SwiftData
import os

@main
struct PantryApp: App {
    private static let logger = Logger(subsystem: "foundation.pantry", category: "startup")
    private static let appSchema = Schema([
            PantryItem.self,
            Category.self,
            StorageLocation.self,
            ShoppingListItem.self,
            Receipt.self,
            ReceiptItem.self,
            BarcodeMapping.self,
            Recipe.self,
            RecipeIngredient.self,
            RecipeInstruction.self,
            RecipeCategory.self,
            RecipeTag.self,
            RecipeCookingNote.self,
            RecipeCollection.self,
            MealPlan.self,
            MealPlanEntry.self,
            MealPlanConstraintProfile.self,
            MealPlanGeneration.self,
            MealPlanEntryReason.self,
            MealPlanFeedback.self
    ])

    var sharedModelContainer: ModelContainer = PantryApp.makeSharedContainer()

    private static func makeSharedContainer() -> ModelContainer {
        // Use an in-memory store when the app is launched by the UI-test runner.
        // This guarantees a clean, isolated data set for every test run and prevents
        // test data from polluting the on-device store (or vice-versa).
        let isUITesting = CommandLine.arguments.contains("-UITesting")
        let fileManager = FileManager.default

        if isUITesting {
            return inMemoryContainer()
        }

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let storeDirectory = appSupport.appendingPathComponent("foundation.pantry", isDirectory: true)
        try? fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

        // Use a versioned store filename so launch can recover cleanly from any
        // previous incompatible schema artifacts on device/simulator.
        let storeURL = storeDirectory.appendingPathComponent("pantry_v2.store")
        let config = ModelConfiguration(schema: appSchema, url: storeURL)

        do {
            return try ModelContainer(for: appSchema, configurations: [config])
        } catch {
            logger.error("Primary ModelContainer init failed: \(String(describing: error), privacy: .public)")
            // If an on-device store is incompatible/corrupt, recover rather than crash.
            backupAndDeleteStore(at: storeURL)
            do {
                return try ModelContainer(for: appSchema, configurations: [config])
            } catch {
                logger.error("ModelContainer retry after store cleanup failed: \(String(describing: error), privacy: .public)")
                // Last-resort fallback to keep the app launchable.
                return inMemoryContainer()
            }
        }
    }

    private static func backupAndDeleteStore(at baseURL: URL) {
        let fileManager = FileManager.default
        let suffixes = ["", "-shm", "-wal"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())

        for suffix in suffixes {
            let fileURL = URL(fileURLWithPath: baseURL.path + suffix)
            guard fileManager.fileExists(atPath: fileURL.path) else { continue }

            let backupURL = URL(fileURLWithPath: fileURL.path + ".backup-\(stamp)")
            _ = try? fileManager.moveItem(at: fileURL, to: backupURL)
            _ = try? fileManager.removeItem(at: fileURL)
        }
    }

    private static func inMemoryContainer() -> ModelContainer {
        let memoryConfig = ModelConfiguration(schema: appSchema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: appSchema, configurations: [memoryConfig])
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
