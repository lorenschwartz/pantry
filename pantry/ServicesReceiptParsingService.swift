//
//  ReceiptParsingService.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import Foundation
import SwiftData

// MARK: - ParsedReceiptItem

/// Structured representation of one line item extracted from receipt OCR text.
struct ParsedReceiptItem {
    var name: String
    var quantity: Double
    var unit: String
    var price: Double?
}

// MARK: - ReceiptParsingService

/// Service for parsing grocery receipt OCR text into structured data.
class ReceiptParsingService {

    // MARK: - Store Name

    /// Returns the first non-empty, non-numeric line of `text` as the store name.
    static func extractStoreName(from text: String) -> String? {
        text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first {
                !$0.isEmpty &&
                !$0.allSatisfy({ $0.isNumber || $0 == "-" || $0 == "/" || $0 == ":" })
            }
    }

    // MARK: - Purchase Date

    /// Scans `text` for a date in MM/DD/YYYY or MM-DD-YYYY format and returns the
    /// first match as a `Date`, or `nil` if no date is found.
    static func extractPurchaseDate(from text: String) -> Date? {
        let pattern = #"\b(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }

        func group(_ i: Int) -> Int? {
            guard let r = Range(match.range(at: i), in: text) else { return nil }
            return Int(text[r])
        }
        guard let month = group(1), let day = group(2), var year = group(3) else { return nil }
        if year < 100 { year += 2000 }

        var comps = DateComponents()
        comps.month = month
        comps.day = day
        comps.year = year
        return Calendar.current.date(from: comps)
    }

    // MARK: - Item Parsing

    /// Keywords that identify non-item lines (totals, taxes, headers, etc.).
    static let skipKeywords: Set<String> = [
        "TOTAL", "TAX", "SUBTOTAL", "DISCOUNT", "SAVINGS",
        "COUPON", "CHANGE", "CASH", "CREDIT", "DEBIT", "BALANCE",
        "THANK", "RECEIPT", "CUSTOMER", "DATE", "TIME",
        "CARD", "VISA", "MASTERCARD", "AMEX", "POINTS"
    ]

    /// Parses raw OCR text into an array of `ParsedReceiptItem`.
    ///
    /// - The first non-empty line is treated as the store name and skipped.
    /// - Lines that match `skipKeywords` or lack a trailing price are excluded.
    static func parseReceiptText(_ text: String) -> [ParsedReceiptItem] {
        guard !text.isEmpty else { return [] }

        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Drop the first non-empty line (store name / header)
        guard lines.count > 1 else { return [] }
        return lines.dropFirst().compactMap { parseLineAsItem($0) }
    }

    /// Attempts to parse a single receipt text line into a `ParsedReceiptItem`.
    ///
    /// Returns `nil` for totals, taxes, date lines, address lines, and any
    /// line that does not end with a recognisable price.
    static func parseLineAsItem(_ line: String) -> ParsedReceiptItem? {
        let upper = line.uppercased().trimmingCharacters(in: .whitespaces)

        // Skip date-only lines (MM/DD/YYYY etc.)
        if upper.range(of: #"^\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\s*$"#,
                       options: .regularExpression) != nil { return nil }

        // Skip lines whose non-price portion matches a skip keyword exactly
        // (handles "TOTAL  15.56" but not "TOTAL FAGE  1.29")
        let nameUpper = removeTrailingPrice(from: upper)
        if skipKeywords.contains(nameUpper) { return nil }

        // Require a trailing price: one or more digits, dot, exactly two digits
        let pricePattern = #"\s+(\d+\.\d{2})\s*$"#
        guard
            let priceRegex = try? NSRegularExpression(pattern: pricePattern),
            let priceMatch = priceRegex.firstMatch(
                in: line, range: NSRange(line.startIndex..., in: line)),
            let priceRange = Range(priceMatch.range(at: 1), in: line),
            let price = Double(line[priceRange])
        else { return nil }

        // Everything before the price is the raw item name
        let nameEnd = line.index(line.startIndex, offsetBy: priceMatch.range.location)
        let rawName = String(line[..<nameEnd]).trimmingCharacters(in: .whitespaces)
        guard !rawName.isEmpty else { return nil }

        // Try to extract a trailing quantity + unit from the name portion
        // Pattern: name + whitespace + decimal-number + whitespace + unit-abbreviation
        let qtyPattern = #"\s+(\d+\.?\d*)\s+(LB|OZ|KG|G|GAL|QT|PT|DZ|CT|EA|PK)\s*$"#
        var name = rawName
        var quantity = 1.0
        var unit = "item"

        if let qtyRegex = try? NSRegularExpression(pattern: qtyPattern, options: .caseInsensitive),
           let qtyMatch = qtyRegex.firstMatch(
               in: rawName, range: NSRange(rawName.startIndex..., in: rawName)),
           let qtyRange = Range(qtyMatch.range(at: 1), in: rawName),
           let unitRange = Range(qtyMatch.range(at: 2), in: rawName) {
            quantity = Double(rawName[qtyRange]) ?? 1.0
            unit = String(rawName[unitRange]).lowercased()
            let nameStop = rawName.index(rawName.startIndex, offsetBy: qtyMatch.range.location)
            name = String(rawName[..<nameStop]).trimmingCharacters(in: .whitespaces)
        }

        guard !name.isEmpty else { return nil }

        // Normalise name: title-case the trimmed string
        return ParsedReceiptItem(
            name: name.capitalized,
            quantity: quantity,
            unit: unit,
            price: price
        )
    }

    // MARK: - Pantry Matching

    /// Returns the best-matching `PantryItem` for a parsed receipt item using
    /// the same fuzzy strategy as `RecipePantryService`.  Returns `nil` when no
    /// match is found.
    static func matchReceiptItem(
        _ item: ParsedReceiptItem,
        to pantryItems: [PantryItem]
    ) -> PantryItem? {
        let itemName = item.name.lowercased()

        if let exact = pantryItems.first(where: { $0.name.lowercased() == itemName }) {
            return exact
        }
        if let fuzzy = pantryItems.first(where: { $0.name.lowercased().contains(itemName) }) {
            return fuzzy
        }
        if let fuzzy = pantryItems.first(where: { itemName.contains($0.name.lowercased()) }) {
            return fuzzy
        }
        return nil
    }

    // MARK: - Private Helpers

    /// Returns `line` with a trailing price pattern removed and whitespace trimmed.
    private static func removeTrailingPrice(from line: String) -> String {
        let pattern = #"\s+\d+\.\d{2}\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return line }
        let range = NSRange(line.startIndex..., in: line)
        return regex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
