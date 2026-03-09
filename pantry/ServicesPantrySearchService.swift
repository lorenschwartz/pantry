import Foundation

struct PantrySearchService {
    static func filter(items: [PantryItem], query: String) -> [PantryItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return items
        }

        return items.filter { item in
            searchableFields(for: item).contains { field in
                field.localizedCaseInsensitiveContains(normalizedQuery)
            }
        }
    }

    private static func searchableFields(for item: PantryItem) -> [String] {
        [
            item.name,
            item.brand,
            item.unit,
            item.notes,
            item.itemDescription,
            item.barcode,
            item.category?.name,
            item.location?.name
        ]
        .compactMap { $0 }
    }
}
