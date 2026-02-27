//
//  ModelsPantryItemTests.swift
//  pantryTests
//

import Testing
import Foundation
@testable import pantry

struct PantryItemTests {

    // MARK: - isExpired

    @Test func isExpired_returnsTrueWhenExpirationDateIsInThePast() {
        let item = PantryItem(
            name: "Old Milk",
            expirationDate: Date().addingTimeInterval(-86400) // 1 day ago
        )
        #expect(item.isExpired == true)
    }

    @Test func isExpired_returnsFalseWhenExpirationDateIsNil() {
        let item = PantryItem(name: "Salt")
        #expect(item.isExpired == false)
    }

    @Test func isExpired_returnsFalseWhenExpirationDateIsInTheFuture() {
        let item = PantryItem(
            name: "Fresh Milk",
            expirationDate: Date().addingTimeInterval(86400) // 1 day from now
        )
        #expect(item.isExpired == false)
    }

    // MARK: - isExpiringSoon

    @Test func isExpiringSoon_returnsTrueWhenExpirationIsWithinSevenDays() {
        let item = PantryItem(
            name: "Cheese",
            expirationDate: Date().addingTimeInterval(3 * 86400) // 3 days
        )
        #expect(item.isExpiringSoon == true)
    }

    @Test func isExpiringSoon_returnsFalseWhenExpirationIsMoreThanSevenDaysAway() {
        let item = PantryItem(
            name: "Honey",
            expirationDate: Date().addingTimeInterval(30 * 86400) // 30 days
        )
        #expect(item.isExpiringSoon == false)
    }

    @Test func isExpiringSoon_returnsFalseWhenExpirationDateIsNil() {
        let item = PantryItem(name: "Rice")
        #expect(item.isExpiringSoon == false)
    }

    @Test func isExpiringSoon_returnsFalseWhenAlreadyExpired() {
        let item = PantryItem(
            name: "Bread",
            expirationDate: Date().addingTimeInterval(-86400) // yesterday
        )
        #expect(item.isExpiringSoon == false)
    }

    // MARK: - daysUntilExpiration

    @Test func daysUntilExpiration_returnsNilWhenNoExpirationDate() {
        let item = PantryItem(name: "Vinegar")
        #expect(item.daysUntilExpiration == nil)
    }

    @Test func daysUntilExpiration_returnsApproximatelyCorrectDayCount() {
        let tenDaysFromNow = Date().addingTimeInterval(10 * 86400)
        let item = PantryItem(name: "Yogurt", expirationDate: tenDaysFromNow)
        let days = item.daysUntilExpiration
        // Calendar arithmetic can land on 9 or 10 depending on time-of-day
        #expect(days != nil)
        #expect(days! >= 9 && days! <= 10)
    }

    @Test func daysUntilExpiration_returnsNegativeValueWhenExpired() {
        let yesterday = Date().addingTimeInterval(-86400)
        let item = PantryItem(name: "Old Yogurt", expirationDate: yesterday)
        let days = item.daysUntilExpiration
        #expect(days != nil)
        #expect(days! < 0)
    }

    // MARK: - isLowStock

    @Test func isLowStock_returnsTrueWhenQuantityIsOne() {
        let item = PantryItem(name: "Butter", quantity: 1)
        #expect(item.isLowStock == true)
    }

    @Test func isLowStock_returnsTrueWhenQuantityIsZero() {
        let item = PantryItem(name: "Coffee", quantity: 0)
        #expect(item.isLowStock == true)
    }

    @Test func isLowStock_returnsFalseWhenQuantityIsGreaterThanOne() {
        let item = PantryItem(name: "Eggs", quantity: 12)
        #expect(item.isLowStock == false)
    }
}
