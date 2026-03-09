import Testing
@testable import pantry

struct PantrySearchServiceTests {

    @Test func filter_returnsAllItemsWhenQueryIsEmpty() {
        let items = [
            PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon"),
            PantryItem(name: "Eggs", quantity: 12, unit: "count")
        ]

        let result = PantrySearchService.filter(items: items, query: "")

        #expect(result.count == 2)
    }

    @Test func filter_matchesName_caseInsensitive() {
        let milk = PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon")
        let eggs = PantryItem(name: "Eggs", quantity: 12, unit: "count")

        let result = PantrySearchService.filter(items: [milk, eggs], query: "MILK")

        #expect(result.count == 1)
        #expect(result.first?.name == "Whole Milk")
    }

    @Test func filter_matchesRelevantMetadata_brandCategoryAndLocation() {
        let dairy = Category(name: "Dairy", colorHex: "#5AC8FA", iconName: "drop")
        let fridge = StorageLocation(name: "Fridge", iconName: "snowflake")

        let yogurt = PantryItem(name: "Greek Yogurt", quantity: 1, unit: "container", brand: "Fage")
        yogurt.category = dairy
        yogurt.location = fridge

        let oil = PantryItem(name: "Olive Oil", quantity: 1, unit: "bottle", brand: "Kirkland")

        let byBrand = PantrySearchService.filter(items: [yogurt, oil], query: "fage")
        #expect(byBrand.count == 1)
        #expect(byBrand.first?.name == "Greek Yogurt")

        let byCategory = PantrySearchService.filter(items: [yogurt, oil], query: "dairy")
        #expect(byCategory.count == 1)
        #expect(byCategory.first?.name == "Greek Yogurt")

        let byLocation = PantrySearchService.filter(items: [yogurt, oil], query: "fridge")
        #expect(byLocation.count == 1)
        #expect(byLocation.first?.name == "Greek Yogurt")
    }

    @Test func filter_returnsNoItemsWhenNothingMatches() {
        let items = [
            PantryItem(name: "Whole Milk", quantity: 1, unit: "gallon"),
            PantryItem(name: "Eggs", quantity: 12, unit: "count")
        ]

        let result = PantrySearchService.filter(items: items, query: "saffron")

        #expect(result.isEmpty)
    }
}
