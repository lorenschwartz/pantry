//
//  ReceiptScanService.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-03-03.
//

import Foundation
import UIKit
import Vision
import SwiftData

// MARK: - Intermediate Value Types

/// A parsed line item extracted from raw OCR text.
/// This is a pure value type — not persisted directly in SwiftData.
/// It acts as a data-transfer object between OCR parsing and the review UI.
struct ParsedReceiptLine: Identifiable, Equatable {
    let id: UUID
    var name: String
    var price: Double?
    var quantity: Double
    var unit: String
    /// Whether the user has selected this line to be saved.  Defaults to `true`.
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        name: String,
        price: Double? = nil,
        quantity: Double = 1.0,
        unit: String = "item",
        isSelected: Bool = true
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.unit = unit
        self.isSelected = isSelected
    }
}

/// The structured result of OCR parsing a receipt image.
/// All fields are optional because OCR quality varies widely.
/// Conforms to `Identifiable` so it can be used directly with `.sheet(item:)`.
struct ParsedReceipt: Identifiable, Equatable {
    let id: UUID = UUID()
    var storeName: String?
    var purchaseDate: Date?
    var totalAmount: Double?
    var lines: [ParsedReceiptLine]
    var rawOCRText: String
}

// MARK: - Errors

enum ReceiptScanError: Error, LocalizedError {
    case invalidImage
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be processed. Please try again."
        case .recognitionFailed(let detail):
            return "Text recognition failed: \(detail)"
        }
    }
}

// MARK: - Service

/// Stateless receipt scanning service.
/// All methods are static following the `RecipePantryService` pattern.
///
/// Responsibilities:
/// 1. Run Vision OCR on a `UIImage`  → raw text string
/// 2. Parse the raw text              → `ParsedReceipt` (pure, testable)
/// 3. Persist the reviewed result     → SwiftData `Receipt` + `ReceiptItem` objects
/// 4. Link saved items to the pantry  → create `PantryItem` for each selected `ReceiptItem`
enum ReceiptScanService {

    // MARK: - OCR (hardware-dependent; not unit-tested)

    /// Runs Vision text recognition on `image` and calls `completion` on the main queue.
    /// - Parameters:
    ///   - image: The receipt image captured from the camera or photo library.
    ///   - completion: Called with `.success(rawText)` or `.failure(error)`.
    static func recognizeText(in image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { completion(.failure(ReceiptScanError.invalidImage)) }
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            // Sort top-to-bottom: VisionKit bounding boxes use bottom-left origin,
            // so a higher minY value means higher on the page.
            let text = observations
                .sorted { $0.boundingBox.minY > $1.boundingBox.minY }
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            DispatchQueue.main.async { completion(.success(text)) }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Parsing (pure; fully unit-tested)

    /// Parses raw OCR text into a structured `ParsedReceipt`.
    static func parse(ocrText: String) -> ParsedReceipt {
        let lines = ocrText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return ParsedReceipt(
            storeName: extractStoreName(from: lines),
            purchaseDate: extractDate(from: lines),
            totalAmount: extractTotal(from: lines),
            lines: extractLineItems(from: lines),
            rawOCRText: ocrText
        )
    }

    /// Extracts a price value from a single OCR line.
    /// Returns the **rightmost** price-looking value (1–3 digits + 2 decimal places).
    /// Returns `nil` when no price is found or when the value exceeds 999.99
    /// (which avoids matching 4-digit totals or product SKUs).
    static func extractPrice(from line: String) -> Double? {
        // Pattern: optional $, optional spaces, 1-3 digits, decimal point, exactly 2 digits.
        // Negative lookbehind/lookahead prevent matching inside larger numbers (e.g. "1000.00").
        let pattern = #"(?<!\d)\$?\s*(\d{1,3}\.\d{2})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, range: range)

        // Take the rightmost match — prices appear at the end of receipt lines
        guard let match = matches.last else { return nil }

        let captureRange = match.range(at: 1)
        guard let swiftRange = Range(captureRange, in: line) else { return nil }
        let priceString = String(line[swiftRange])

        return Double(priceString)
    }

    /// Title-cases `raw` and strips leading all-digit tokens (e.g. PLU codes like "4011 BANANA").
    /// Returns `nil` when the cleaned result is fewer than 3 characters.
    static func normalizeName(_ raw: String) -> String? {
        var tokens = raw
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Drop leading numeric tokens (PLU codes, item counts)
        while let first = tokens.first, first.allSatisfy({ $0.isNumber }) {
            tokens.removeFirst()
        }

        let joined = tokens.joined(separator: " ")
        guard joined.count >= 3 else { return nil }
        return joined.capitalized
    }

    /// Returns the likely store name from a collection of OCR lines.
    /// Heuristic: the first non-price line whose `normalizeName` result is non-nil.
    static func extractStoreName(from lines: [String]) -> String? {
        for line in lines {
            // Skip lines that contain a price (those are item lines, not a header)
            guard extractPrice(from: line) == nil else { continue }
            // Skip phone numbers (contain parentheses or "tel"/"phone")
            let lower = line.lowercased()
            guard !lower.contains("tel") && !lower.contains("phone") && !line.contains("(") else { continue }
            if let name = normalizeName(line) {
                return name
            }
        }
        return nil
    }

    /// Cached `DateFormatter` instances — `DateFormatter` is expensive to allocate.
    private static let dateFormatters: [DateFormatter] = [
        "MM/dd/yyyy", "MM/dd/yy",
        "M/d/yyyy",   "M/d/yy",
        "yyyy-MM-dd", "MM-dd-yyyy"
    ].map {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = $0
        return f
    }

    /// Scans lines for a recognisable date string.
    /// Supports formats: MM/dd/yyyy, MM/dd/yy, M/d/yyyy, M/d/yy, yyyy-MM-dd, MM-dd-yyyy.
    static func extractDate(from lines: [String]) -> Date? {
        // Regex to find date-shaped tokens
        let datePattern = #"\d{1,4}[/\-]\d{1,2}[/\-]\d{2,4}"#
        guard let regex = try? NSRegularExpression(pattern: datePattern) else { return nil }

        for line in lines {
            let nsRange = NSRange(line.startIndex..., in: line)
            guard let match = regex.firstMatch(in: line, range: nsRange),
                  let swiftRange = Range(match.range, in: line) else { continue }

            let token = String(line[swiftRange])
            for formatter in dateFormatters {
                if let date = formatter.date(from: token) {
                    return date
                }
            }
        }
        return nil
    }

    /// Returns the receipt total amount.
    /// Searches from the bottom of the receipt upward; prefers lines containing
    /// exactly "total" (not "subtotal").
    static func extractTotal(from lines: [String]) -> Double? {
        for line in lines.reversed() {
            let lower = line.lowercased()
            guard lower.contains("total"), !lower.contains("subtotal") else { continue }
            if let price = extractPrice(from: line) {
                return price
            }
        }
        return nil
    }

    /// Extracts purchasable line items from an OCR line array.
    /// A line is included when it has a recognisable price AND its name does not
    /// contain any skip keywords (tax, total, payment method, etc.).
    static func extractLineItems(from lines: [String]) -> [ParsedReceiptLine] {
        let skipKeywords: Set<String> = [
            "total", "tax", "hst", "gst", "pst", "subtotal",
            "change", "cash", "visa", "mastercard", "amex", "debit",
            "savings", "discount", "thank you", "tel", "phone",
            "balance", "points", "reward"
        ]

        // Regex to strip a trailing price from the right side of a line
        let trailingPricePattern = #"\s*\$?\s*\d{1,3}\.\d{2}\s*$"#

        var result: [ParsedReceiptLine] = []

        for line in lines {
            let lower = line.lowercased()

            // Skip lines that contain any skip keyword
            guard !skipKeywords.contains(where: { lower.contains($0) }) else { continue }

            // Must have a parseable price
            guard let price = extractPrice(from: line) else { continue }

            // Derive name by stripping the price from the right side of the line
            let namePart = line
                .replacingOccurrences(of: trailingPricePattern, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            guard let name = normalizeName(namePart) else { continue }

            result.append(ParsedReceiptLine(name: name, price: price))
        }

        return result
    }

    // MARK: - Persistence

    /// Saves a reviewed `ParsedReceipt` to SwiftData.
    /// Only lines where `isSelected == true` are saved as `ReceiptItem` objects.
    /// - Returns: The inserted `Receipt` object (discardable).
    @discardableResult
    static func saveReceipt(
        _ parsed: ParsedReceipt,
        image: UIImage?,
        context: ModelContext
    ) -> Receipt {
        let receipt = Receipt(
            storeName: parsed.storeName,
            purchaseDate: parsed.purchaseDate ?? Date(),
            totalAmount: parsed.totalAmount,
            imageData: image.flatMap { $0.jpegData(compressionQuality: 0.8) },
            rawOCRText: parsed.rawOCRText.isEmpty ? nil : parsed.rawOCRText
        )
        context.insert(receipt)

        let receiptItems: [ReceiptItem] = parsed.lines
            .filter { $0.isSelected }
            .map { line in
                ReceiptItem(
                    name: line.name,
                    quantity: line.quantity,
                    unit: line.unit,
                    price: line.price
                )
            }

        for item in receiptItems {
            context.insert(item)
            item.receipt = receipt
        }
        receipt.items = receiptItems

        try? context.save()
        return receipt
    }

    /// Creates a `PantryItem` from a saved `ReceiptItem` and links them together.
    /// Safe to call multiple times — subsequent calls are no-ops (idempotent).
    static func addReceiptItemToPantry(
        _ receiptItem: ReceiptItem,
        receipt: Receipt,
        context: ModelContext
    ) {
        guard !receiptItem.isAddedToPantry else { return }

        let pantryItem = PantryItem(
            name: receiptItem.name,
            quantity: receiptItem.quantity,
            unit: receiptItem.unit,
            price: receiptItem.price,
            purchaseDate: receipt.purchaseDate
        )
        context.insert(pantryItem)

        receiptItem.pantryItem = pantryItem
        receiptItem.isAddedToPantry = true

        try? context.save()
    }

    /// Adds every not-yet-added `ReceiptItem` in a receipt to the pantry.
    static func addAllItemsToPantry(receipt: Receipt, context: ModelContext) {
        guard let items = receipt.items else { return }
        for item in items {
            addReceiptItemToPantry(item, receipt: receipt, context: context)
        }
    }
}
