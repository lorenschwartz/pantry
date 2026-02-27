//
//  NotificationService.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import Foundation
import UserNotifications

/// Service for scheduling, updating, and cancelling local notifications for expiration
/// and low-stock events.
///
/// Methods that call `UNUserNotificationCenter` are *not* unit-tested (Apple framework
/// behaviour).  The pure helper methods — `itemsNeedingExpirationNotification`,
/// `expirationNotificationIdentifier`, `buildExpirationTitle`, and `buildExpirationBody`
/// — are fully covered by `ServicesNotificationServiceTests`.
class NotificationService {

    // MARK: - Permission

    /// Requests `.alert`, `.sound`, and `.badge` notification permission if the user
    /// has not yet been asked.  Safe to call every launch; the system shows the prompt
    /// only once.
    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Scheduling

    /// Schedules a local notification for each item expiring within `daysAhead` days.
    /// Existing notifications for the same item are replaced (same identifier).
    static func scheduleExpirationNotifications(
        for items: [PantryItem],
        daysAhead: Int = 3
    ) {
        let center = UNUserNotificationCenter.current()
        let qualifying = itemsNeedingExpirationNotification(from: items, daysAhead: daysAhead)

        for item in qualifying {
            guard let trigger = expirationTrigger(for: item) else { continue }

            let content = UNMutableNotificationContent()
            content.title = buildExpirationTitle(for: item)
            content.body = buildExpirationBody(for: item) ?? ""
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: expirationNotificationIdentifier(for: item),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// Schedules a single low-stock summary notification listing up to three item names.
    /// Fires after a short delay so multiple rapid calls can be coalesced by the OS.
    static func scheduleLowStockNotification(for items: [PantryItem]) {
        guard !items.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        if items.count == 1 {
            content.body = "\(items[0].name) is running low. Add it to your shopping list."
        } else {
            let listed = items.prefix(3).map(\.name).joined(separator: ", ")
            let tail = items.count > 3 ? " and \(items.count - 3) more" : ""
            content.body = "\(listed)\(tail) are running low."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pantry.lowstock",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels any pending expiration notification for `item` (e.g. when the item is
    /// deleted or its expiration date is changed).
    static func cancelNotification(for item: PantryItem) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [expirationNotificationIdentifier(for: item)])
    }

    /// Cancels every pending notification scheduled by this service.
    static func cancelAllPantryNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Pure helpers (unit-tested)

    /// Returns items that have an expiration date strictly in the future but within
    /// `daysAhead` calendar days.
    static func itemsNeedingExpirationNotification(
        from items: [PantryItem],
        daysAhead: Int = 3
    ) -> [PantryItem] {
        let now = Date()
        guard let cutoff = Calendar.current.date(byAdding: .day, value: daysAhead, to: now)
        else { return [] }

        return items.filter {
            guard let exp = $0.expirationDate else { return false }
            return exp > now && exp <= cutoff
        }
    }

    /// Stable, unique identifier for a pantry item's expiration notification.
    static func expirationNotificationIdentifier(for item: PantryItem) -> String {
        "pantry.expiration.\(item.id.uuidString)"
    }

    /// Short notification banner title.
    static func buildExpirationTitle(for item: PantryItem) -> String {
        "\(item.name) is expiring soon"
    }

    /// Notification body with days remaining.  Returns `nil` when the item has no
    /// expiration date.
    static func buildExpirationBody(for item: PantryItem) -> String? {
        guard let days = item.daysUntilExpiration else { return nil }
        if days <= 0 { return "Expires today — use it or it'll go to waste." }
        return "Expires in \(days) day\(days == 1 ? "" : "s")."
    }

    // MARK: - Private

    private static func expirationTrigger(
        for item: PantryItem
    ) -> UNCalendarNotificationTrigger? {
        guard let exp = item.expirationDate else { return nil }
        // Notify at 9 AM on the day of expiration
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: exp)
        comps.hour = 9
        comps.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }
}
