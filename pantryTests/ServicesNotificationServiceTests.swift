//
//  ServicesNotificationServiceTests.swift
//  pantryTests
//
//  Tests cover the pure helper methods on NotificationService.
//  Methods that call UNUserNotificationCenter are Apple framework behaviour and
//  are not unit-tested per the project's CLAUDE.md testing conventions.
//

import Testing
import Foundation
@testable import pantry

// MARK: - itemsNeedingExpirationNotification

struct ItemsNeedingExpirationNotificationTests {

    @Test func itemsNeedingExpiration_includesItemExpiringWithinWindow() {
        let item = PantryItem(
            name: "Yogurt",
            expirationDate: Date().addingTimeInterval(2 * 86400) // 2 days from now
        )
        let result = NotificationService.itemsNeedingExpirationNotification(
            from: [item], daysAhead: 3)
        #expect(result.count == 1)
    }

    @Test func itemsNeedingExpiration_excludesAlreadyExpiredItems() {
        let expired = PantryItem(
            name: "Old Milk",
            expirationDate: Date().addingTimeInterval(-86400) // 1 day ago
        )
        let result = NotificationService.itemsNeedingExpirationNotification(
            from: [expired], daysAhead: 3)
        #expect(result.isEmpty)
    }

    @Test func itemsNeedingExpiration_excludesItemsFarInFuture() {
        let farFuture = PantryItem(
            name: "Canned Beans",
            expirationDate: Date().addingTimeInterval(365 * 86400)
        )
        let result = NotificationService.itemsNeedingExpirationNotification(
            from: [farFuture], daysAhead: 3)
        #expect(result.isEmpty)
    }

    @Test func itemsNeedingExpiration_excludesItemsWithNoExpirationDate() {
        let item = PantryItem(name: "Salt") // no expiration date
        let result = NotificationService.itemsNeedingExpirationNotification(
            from: [item], daysAhead: 3)
        #expect(result.isEmpty)
    }

    @Test func itemsNeedingExpiration_returnsEmptyForEmptyInput() {
        let result = NotificationService.itemsNeedingExpirationNotification(
            from: [], daysAhead: 3)
        #expect(result.isEmpty)
    }

    @Test func itemsNeedingExpiration_includesItemExpiringExactlyAtCutoff() {
        // An item expiring just under `daysAhead` days from now
        let item = PantryItem(
            name: "Cheese",
            expirationDate: Date().addingTimeInterval(3 * 86400 - 60) // ~3 days minus a minute
        )
        let result = NotificationService.itemsNeedingExpirationNotification(
            from: [item], daysAhead: 3)
        #expect(result.count == 1)
    }

    @Test func itemsNeedingExpiration_respectsCustomDaysAheadWindow() {
        let soonItem = PantryItem(
            name: "Milk",
            expirationDate: Date().addingTimeInterval(2 * 86400)
        )
        let laterItem = PantryItem(
            name: "Cheese",
            expirationDate: Date().addingTimeInterval(6 * 86400)
        )
        let narrow = NotificationService.itemsNeedingExpirationNotification(
            from: [soonItem, laterItem], daysAhead: 3)
        let wide = NotificationService.itemsNeedingExpirationNotification(
            from: [soonItem, laterItem], daysAhead: 7)
        #expect(narrow.count == 1)
        #expect(wide.count == 2)
    }
}

// MARK: - expirationNotificationIdentifier

struct ExpirationNotificationIdentifierTests {

    @Test func identifier_containsItemUUIDString() {
        let item = PantryItem(name: "Milk")
        let id = NotificationService.expirationNotificationIdentifier(for: item)
        #expect(id.contains(item.id.uuidString))
    }

    @Test func identifier_hasPantryExpirationPrefix() {
        let item = PantryItem(name: "Milk")
        let id = NotificationService.expirationNotificationIdentifier(for: item)
        #expect(id.hasPrefix("pantry.expiration."))
    }

    @Test func identifier_isUniquePerItem() {
        let a = PantryItem(name: "Milk")
        let b = PantryItem(name: "Eggs")
        let idA = NotificationService.expirationNotificationIdentifier(for: a)
        let idB = NotificationService.expirationNotificationIdentifier(for: b)
        #expect(idA != idB)
    }
}

// MARK: - buildExpirationTitle

struct BuildExpirationTitleTests {

    @Test func buildExpirationTitle_containsItemName() {
        let item = PantryItem(
            name: "Whole Milk",
            expirationDate: Date().addingTimeInterval(86400)
        )
        let title = NotificationService.buildExpirationTitle(for: item)
        #expect(title.contains("Whole Milk"))
    }

    @Test func buildExpirationTitle_isNonEmpty() {
        let item = PantryItem(name: "Eggs")
        #expect(!NotificationService.buildExpirationTitle(for: item).isEmpty)
    }
}

// MARK: - buildExpirationBody

struct BuildExpirationBodyTests {

    @Test func buildExpirationBody_returnsNilForItemWithNoExpirationDate() {
        let item = PantryItem(name: "Salt")
        #expect(NotificationService.buildExpirationBody(for: item) == nil)
    }

    @Test func buildExpirationBody_returnsNonNilForItemWithExpirationDate() {
        let item = PantryItem(
            name: "Yogurt",
            expirationDate: Date().addingTimeInterval(2 * 86400)
        )
        #expect(NotificationService.buildExpirationBody(for: item) != nil)
    }

    @Test func buildExpirationBody_mentionsDaysRemaining() {
        let twoDays = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let item = PantryItem(name: "Yogurt", expirationDate: twoDays)
        let body = NotificationService.buildExpirationBody(for: item)
        #expect(body?.contains("2") == true)
    }

    @Test func buildExpirationBody_usesSingularDayForOneDay() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let item = PantryItem(name: "Cream", expirationDate: tomorrow)
        let body = NotificationService.buildExpirationBody(for: item) ?? ""
        // Should say "day" not "days"
        #expect(body.contains("1 day") && !body.contains("1 days"))
    }

    @Test func buildExpirationBody_handlesTodayExpiration() {
        // daysUntilExpiration returns 0 for same-day expiration
        let nearMidnight = Calendar.current.startOfDay(for: Date())
        let item = PantryItem(name: "Bread", expirationDate: nearMidnight)
        let body = NotificationService.buildExpirationBody(for: item)
        #expect(body != nil)
        #expect(body?.contains("today") == true)
    }
}
