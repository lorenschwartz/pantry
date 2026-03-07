//
//  pantryUITests.swift
//  pantryUITests
//
//  Regression test suite — run after every build.
//
//  Each test launches the app with the "-UITesting" flag, which switches
//  pantryApp.swift to an in-memory SwiftData store.  This guarantees a
//  completely clean, isolated store for every test and means tests never
//  depend on (or corrupt) the user's real pantry data.
//
//  Test ID conventions:
//    TC-01  App launches without crashing
//    TC-02  All primary tabs are reachable
//    TC-03  Pantry empty-state shown on a clean store
//    TC-04  Shopping-list empty-state shown on a clean store
//    TC-05  Adding a pantry item makes it appear in the list
//    TC-06  Adding a shopping-list item makes it appear in the list
//    TC-07  Pantry filter menu opens; no duplicate location entries
//    TC-08  Checking off a shopping item shows the "checked" count
//    TC-09  Tapping a pantry item navigates to its detail view
//    TC-10  Swipe-to-delete removes a pantry item from the list
//

import XCTest

final class PantryRegressionTests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Suite Setup

    override func setUpWithError() throws {
        // Stop on first failure so a broken app state doesn't cascade.
        continueAfterFailure = false

        app = XCUIApplication()
        // Tell the app to use an in-memory SwiftData store (see pantryApp.swift).
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-01  App launch
    // ─────────────────────────────────────────────────────────────────────────

    /// Regression: the app was crashing at launch because `initializeDefaultData()`
    /// deleted duplicate Category/StorageLocation rows from SwiftData while `@Query`
    /// held live in-memory references to those same objects.
    /// Fix: store-level dedup was removed; UI-level dedup (uniqueCategories /
    /// uniqueLocations computed properties) is used instead.
    @MainActor
    func test_TC01_appLaunchesWithoutCrashing() throws {
        XCTAssertEqual(app.state, .runningForeground,
                       "App should be running in the foreground after launch")
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5),
                      "Main tab bar should be visible after launch")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-02  Tab navigation
    // ─────────────────────────────────────────────────────────────────────────

    /// All five main tabs must be reachable without crashing.
    @MainActor
    func test_TC02_allPrimaryTabsAreReachable() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // Pantry is the default/selected tab on launch.
        XCTAssertTrue(app.navigationBars["Pantry"].waitForExistence(timeout: 5),
                      "Pantry navigation bar should be visible on launch")

        // Shopping
        tabBar.buttons["Shopping"].tap()
        XCTAssertTrue(app.navigationBars["Shopping List"].waitForExistence(timeout: 5),
                      "Shopping List navigation bar should appear")

        // Recipes
        tabBar.buttons["Recipes"].tap()
        XCTAssertTrue(app.navigationBars["Recipes"].waitForExistence(timeout: 5),
                      "Recipes navigation bar should appear")

        // Receipts
        tabBar.buttons["Receipts"].tap()
        XCTAssertTrue(app.navigationBars["Receipts"].waitForExistence(timeout: 5),
                      "Receipts navigation bar should appear")

        // Return to Pantry
        tabBar.buttons["Pantry"].tap()
        XCTAssertTrue(app.navigationBars["Pantry"].waitForExistence(timeout: 5),
                      "Should navigate back to Pantry tab")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-03  Pantry empty state
    // ─────────────────────────────────────────────────────────────────────────

    /// A clean in-memory store should show the "No Items" ContentUnavailableView
    /// with a prompt to add the first item.
    @MainActor
    func test_TC03_pantryEmptyState_shownOnCleanStore() throws {
        XCTAssertTrue(app.staticTexts["No Items"].waitForExistence(timeout: 5),
                      "Pantry should show 'No Items' empty state when the store is empty")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-04  Shopping-list empty state
    // ─────────────────────────────────────────────────────────────────────────

    /// A clean in-memory store should show the "Shopping List Empty" state.
    @MainActor
    func test_TC04_shoppingListEmptyState_shownOnCleanStore() throws {
        app.tabBars.firstMatch.buttons["Shopping"].tap()
        XCTAssertTrue(app.staticTexts["Shopping List Empty"].waitForExistence(timeout: 5),
                      "Shopping should show 'Shopping List Empty' when the store is empty")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-05  Add pantry item
    // ─────────────────────────────────────────────────────────────────────────

    /// Tapping +, entering a name and tapping Save should add the item to the list.
    @MainActor
    func test_TC05_addPantryItem_appearsInList() throws {
        let addButton = app.navigationBars["Pantry"].buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // The "Add Item" sheet should appear.
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 5))

        // Save should be disabled until a name is entered.
        let saveButton = app.navigationBars["Add Item"].buttons["Save"]
        XCTAssertFalse(saveButton.isEnabled,
                       "Save button should be disabled before a name is entered")

        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Whole Milk")

        XCTAssertTrue(saveButton.isEnabled,
                      "Save button should be enabled after a name is entered")
        saveButton.tap()

        // The new item must appear in the Pantry list.
        XCTAssertTrue(app.staticTexts["Whole Milk"].waitForExistence(timeout: 5),
                      "Newly added item 'Whole Milk' should appear in the pantry list")

        // The "No Items" empty state must be gone.
        XCTAssertFalse(app.staticTexts["No Items"].exists,
                       "'No Items' empty state should be hidden after adding an item")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-06  Add shopping-list item
    // ─────────────────────────────────────────────────────────────────────────

    /// Tapping + on the Shopping tab, entering a name and tapping Add should
    /// add the item to the shopping list.
    @MainActor
    func test_TC06_addShoppingItem_appearsInList() throws {
        app.tabBars.firstMatch.buttons["Shopping"].tap()

        let addButton = app.navigationBars["Shopping List"].buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add to List"].waitForExistence(timeout: 5))

        // Add button should be disabled until a name is entered.
        let addConfirmButton = app.navigationBars["Add to List"].buttons["Add"]
        XCTAssertFalse(addConfirmButton.isEnabled,
                       "Add button should be disabled before a name is entered")

        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Sourdough Bread")

        XCTAssertTrue(addConfirmButton.isEnabled,
                      "Add button should be enabled after a name is entered")
        addConfirmButton.tap()

        // The item must appear in the shopping list.
        XCTAssertTrue(app.staticTexts["Sourdough Bread"].waitForExistence(timeout: 5),
                      "Newly added item should appear in the shopping list")

        // The empty state must be gone.
        XCTAssertFalse(app.staticTexts["Shopping List Empty"].exists,
                       "Empty state should be hidden after an item is added")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-07  Pantry filter menu — no duplicate location entries
    // ─────────────────────────────────────────────────────────────────────────

    /// Regression: a seeding race condition could insert duplicate Category /
    /// StorageLocation rows.  The fix deduplicates at the UI layer
    /// (uniqueLocations / uniqueCategories computed properties).
    ///
    /// With a fresh in-memory store, `initializeDefaultData()` runs once and
    /// the filter menu must list each location exactly once.
    @MainActor
    func test_TC07_pantryFilterMenu_opensAndHasNoDuplicateLocations() throws {
        // The options button (sort + filter menu)
        let optionsButton = app.navigationBars["Pantry"].buttons["Options"]
        XCTAssertTrue(optionsButton.waitForExistence(timeout: 5),
                      "Options button should be present in the Pantry navigation bar")
        optionsButton.tap()

        // Navigate into the "Filter by Location" submenu.
        let filterByLocation = app.buttons["Filter by Location"]
        XCTAssertTrue(filterByLocation.waitForExistence(timeout: 3),
                      "'Filter by Location' option should be visible in the Options menu")
        filterByLocation.tap()

        // The "All Locations" reset option must be present.
        XCTAssertTrue(app.buttons["All Locations"].waitForExistence(timeout: 3),
                      "'All Locations' button should be present in the location filter submenu")

        // Each default location should appear exactly once.
        // Duplicates here are the regression signal.
        let refrigeratorButtons = app.buttons.matching(
            NSPredicate(format: "label == 'Refrigerator'")
        )
        XCTAssertEqual(refrigeratorButtons.count, 1,
                       "'Refrigerator' should appear exactly once — " +
                       "more than one indicates a seeding/dedup regression")

        let freezerButtons = app.buttons.matching(
            NSPredicate(format: "label == 'Freezer'")
        )
        XCTAssertEqual(freezerButtons.count, 1,
                       "'Freezer' should appear exactly once in the location filter")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-08  Check off a shopping item
    // ─────────────────────────────────────────────────────────────────────────

    /// Tapping the checkbox of a shopping-list item should move it to the
    /// "checked" bucket and update the summary bar count.
    @MainActor
    func test_TC08_checkingShoppingItem_showsCheckedCountInSummaryBar() throws {
        app.tabBars.firstMatch.buttons["Shopping"].tap()

        // Add an item.
        app.navigationBars["Shopping List"].buttons["Add Item"].tap()
        XCTAssertTrue(app.navigationBars["Add to List"].waitForExistence(timeout: 5))
        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3),
                      "Item Name text field should be visible in the Add to List sheet")
        nameField.tap()
        nameField.typeText("Eggs")
        app.navigationBars["Add to List"].buttons["Add"].tap()

        // Confirm item is visible.
        XCTAssertTrue(app.staticTexts["Eggs"].waitForExistence(timeout: 5))

        // The checkbox is the first (and only free-standing) button in the item row.
        // PantryItemRow layout: [checkboxButton] [VStack with text] [Spacer] [badge image]
        let eggsCell = app.cells.containing(.staticText, identifier: "Eggs").firstMatch
        XCTAssertTrue(eggsCell.waitForExistence(timeout: 3))
        eggsCell.buttons.firstMatch.tap()

        // The summary bar should now show "1 checked".
        let checkedSummaryButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS '1 checked'")
        ).firstMatch
        XCTAssertTrue(checkedSummaryButton.waitForExistence(timeout: 5),
                      "Summary bar should show '1 checked' after checking off an item")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-09  Pantry item detail navigation
    // ─────────────────────────────────────────────────────────────────────────

    /// Tapping a pantry-list row should push the ItemDetailView, and tapping
    /// the back button should return to the list.
    @MainActor
    func test_TC09_tappingPantryItem_navigatesToDetailViewAndBack() throws {
        // Add an item to tap.
        let addButton = app.navigationBars["Pantry"].buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 5))
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText("Almond Butter")
        app.navigationBars["Add Item"].buttons["Save"].tap()

        // Tap the item cell to push the detail view.
        let cell = app.cells.containing(.staticText, identifier: "Almond Butter").firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()

        // Detail view should use the item name as the navigation bar title.
        XCTAssertTrue(app.navigationBars["Almond Butter"].waitForExistence(timeout: 5),
                      "Item detail view should have the item name as navigation title")

        // Navigate back to the Pantry list.
        app.navigationBars["Almond Butter"].buttons["Pantry"].tap()
        XCTAssertTrue(app.navigationBars["Pantry"].waitForExistence(timeout: 5),
                      "Should return to Pantry list after tapping Back")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TC-10  Swipe to delete a pantry item
    // ─────────────────────────────────────────────────────────────────────────

    /// Swiping a pantry row left and tapping the destructive Delete action
    /// should remove the item from the list immediately (no confirmation).
    @MainActor
    func test_TC10_swipeToDelete_removesPantryItemFromList() throws {
        // Add an item to delete.
        let addButton = app.navigationBars["Pantry"].buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 5))
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText("Delete Me Item")
        app.navigationBars["Add Item"].buttons["Save"].tap()

        // Confirm the item is in the list.
        let cell = app.cells.containing(.staticText, identifier: "Delete Me Item").firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5))

        // Swipe left to reveal the trailing swipe actions.
        cell.swipeLeft()

        // Tap the destructive Delete button (no confirmation dialog — direct delete).
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        deleteButton.tap()

        // The item must no longer be in the list.
        XCTAssertFalse(
            app.staticTexts["Delete Me Item"].waitForExistence(timeout: 3),
            "Item should be removed from the list after swipe-delete"
        )

        // The Pantry list should be empty again → empty state should return.
        XCTAssertTrue(app.staticTexts["No Items"].waitForExistence(timeout: 3),
                      "'No Items' empty state should reappear after deleting the only item")
    }
}
