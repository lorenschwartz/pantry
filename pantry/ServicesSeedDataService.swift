//
//  SeedDataService.swift
//  pantry
//
//  Populates the database with representative sample data covering every
//  UI screen.  Trigger from Settings → Developer → "Seed Sample Data".
//
//  Relationship setup follows the insert-first pattern required by SwiftData:
//  insert the parent, initialise its array, insert each child, then append.
//

import Foundation
import SwiftData

struct SeedDataService {

    // MARK: - Public Entry Points

    /// Seeds only when the store is empty (no categories present).
    static func seedIfNeeded(context: ModelContext) throws {
        let count = try context.fetchCount(FetchDescriptor<Category>())
        guard count == 0 else { return }
        try seed(context: context)
    }

    /// Unconditionally inserts a full set of sample data and saves.
    static func seed(context: ModelContext) throws {
        let cats  = seedCategories(context: context)
        let locs  = seedLocations(context: context)
        let rCats = seedRecipeCategories(context: context)
        let rTags = seedRecipeTags(context: context)
        let cols  = seedCollections(context: context)
        let items = seedPantryItems(context: context, categories: cats, locations: locs)
        seedRecipes(context: context,
                    recipeCategories: rCats,
                    recipeTags: rTags,
                    collections: cols,
                    pantryItems: items)
        seedShoppingList(context: context, categories: cats)
        seedReceipts(context: context)
        try context.save()
    }

    // MARK: - Categories

    @discardableResult
    private static func seedCategories(context: ModelContext) -> [String: Category] {
        var map: [String: Category] = [:]
        for cat in Category.defaultCategories {
            context.insert(cat)
            map[cat.name] = cat
        }
        return map
    }

    // MARK: - Storage Locations

    @discardableResult
    private static func seedLocations(context: ModelContext) -> [String: StorageLocation] {
        var map: [String: StorageLocation] = [:]
        for loc in StorageLocation.defaultLocations {
            context.insert(loc)
            map[loc.name] = loc
        }
        return map
    }

    // MARK: - Recipe Categories

    @discardableResult
    private static func seedRecipeCategories(context: ModelContext) -> [String: RecipeCategory] {
        var map: [String: RecipeCategory] = [:]
        for rc in RecipeCategory.defaultCategories {
            context.insert(rc)
            map[rc.name] = rc
        }
        return map
    }

    // MARK: - Recipe Tags

    @discardableResult
    private static func seedRecipeTags(context: ModelContext) -> [String: RecipeTag] {
        var map: [String: RecipeTag] = [:]
        for tag in RecipeTag.defaultTags {
            context.insert(tag)
            map[tag.name] = tag
        }
        return map
    }

    // MARK: - Recipe Collections

    @discardableResult
    private static func seedCollections(context: ModelContext) -> [String: RecipeCollection] {
        let collections: [RecipeCollection] = [
            RecipeCollection(
                name: "Weeknight Dinners",
                description: "Quick and easy meals for busy evenings",
                iconName: "moon.stars",
                colorHex: "#5E5CE6",
                sortOrder: 0
            ),
            RecipeCollection(
                name: "Baking & Desserts",
                description: "Sweet treats and baked goods",
                iconName: "birthday.cake",
                colorHex: "#FF6482",
                sortOrder: 1
            ),
            RecipeCollection(
                name: "Meal Prep Favorites",
                description: "Recipes that reheat beautifully",
                iconName: "refrigerator",
                colorHex: "#34C759",
                sortOrder: 2
            )
        ]
        var map: [String: RecipeCollection] = [:]
        for col in collections {
            context.insert(col)
            map[col.name] = col
        }
        return map
    }

    // MARK: - Pantry Items

    @discardableResult
    private static func seedPantryItems(
        context: ModelContext,
        categories: [String: Category],
        locations: [String: StorageLocation]
    ) -> [String: PantryItem] {

        let now = Date()
        let cal = Calendar.current

        // (name, qty, unit, brand, price, daysUntilExpiry, categoryKey, locationKey)
        // Negative daysUntilExpiry = already expired; nil = no expiry date
        typealias Spec = (String, Double, String, String?, Double?, Int?, String, String)

        let specs: [Spec] = [
            // DAIRY — Refrigerator
            ("Whole Milk",        1,   "gallon",  "Organic Valley",        6.49,   5,    "Dairy",      "Refrigerator"),
            ("Cheddar Cheese",    0.5, "lb",      "Tillamook",             4.99,   2,    "Dairy",      "Refrigerator"), // expiring very soon
            ("Butter",            2,   "sticks",  "Kerrygold",             3.49,   60,   "Dairy",      "Refrigerator"),
            ("Heavy Cream",       1,   "cup",     nil,                     2.99,   7,    "Dairy",      "Refrigerator"),
            ("Parmesan",          1,   "cup",     "BelGioioso",            5.49,   90,   "Dairy",      "Refrigerator"),
            ("Yogurt",            2,   "cups",    "Chobani",               1.89,  -2,    "Dairy",      "Refrigerator"), // EXPIRED

            // PRODUCE — Counter / Refrigerator
            ("Garlic",            3,   "cloves",  nil,                     0.99,   14,   "Produce",    "Counter"),
            ("Yellow Onion",      2,   "medium",  nil,                     1.49,   21,   "Produce",    "Counter"),
            ("Baby Spinach",      1,   "bag",     "Earthbound Farm",       3.99,   1,    "Produce",    "Refrigerator"), // expiring tomorrow
            ("Bell Peppers",      3,   "count",   nil,                     2.49,   5,    "Produce",    "Refrigerator"),
            ("Carrots",           1,   "lb",      nil,                     1.29,   10,   "Produce",    "Refrigerator"),
            ("Lemon",             4,   "count",   nil,                     0.89,   7,    "Produce",    "Refrigerator"),

            // PROTEINS — Refrigerator / Freezer
            ("Chicken Breast",    2,   "lbs",     nil,                     8.99,   3,    "Proteins",   "Refrigerator"),
            ("Eggs",             12,   "count",   "Happy Egg",             5.49,   14,   "Proteins",   "Refrigerator"),
            ("Pancetta",          4,   "oz",      nil,                     4.29,   6,    "Proteins",   "Refrigerator"),
            ("Ground Beef",       1,   "lb",      "Laura's Lean",          6.99,   30,   "Proteins",   "Freezer"),

            // GRAINS — Pantry / Counter
            ("Spaghetti",         1,   "lb",      "Barilla",               1.89,   730,  "Grains",     "Pantry"),
            ("Jasmine Rice",      2,   "cups",    "Lundberg",              3.49,   730,  "Grains",     "Pantry"),
            ("Sourdough Bread",   1,   "loaf",    nil,                     4.99,   3,    "Grains",     "Counter"),
            ("All-Purpose Flour", 3,   "cups",    "King Arthur",           4.79,   365,  "Grains",     "Pantry"),

            // CONDIMENTS — Pantry
            ("Olive Oil",         1,   "bottle",  "California Olive Ranch", 11.99, 365,  "Condiments", "Pantry"),
            ("Soy Sauce",         1,   "bottle",  "Kikkoman",              3.29,   730,  "Condiments", "Pantry"),
            ("Sriracha",          1,   "bottle",  "Huy Fong",              3.49,   730,  "Condiments", "Pantry"),

            // BAKING — Pantry
            ("Sugar",             2,   "cups",    "Domino",                3.49,   730,  "Baking",     "Pantry"),
            ("Brown Sugar",       1,   "cup",     nil,                     2.99,   730,  "Baking",     "Pantry"),
            ("Chocolate Chips",   2,   "cups",    "Ghirardelli",           4.49,   240,  "Baking",     "Pantry"),
            ("Vanilla Extract",   1,   "bottle",  "Nielsen-Massey",        8.99,   1460, "Baking",     "Pantry"),
            ("Baking Soda",       1,   "box",     "Arm & Hammer",          1.49,   365,  "Baking",     "Pantry"),

            // BEVERAGES
            ("Orange Juice",      1,   "carton",  "Tropicana",             4.29,   10,   "Beverages",  "Refrigerator"),
            ("Coffee Beans",      1,   "bag",     "Blue Bottle",           16.99,  90,   "Beverages",  "Pantry"),

            // CANNED — Pantry
            ("Diced Tomatoes",    2,   "cans",    "Muir Glen",             2.49,   730,  "Canned",     "Pantry"),
            ("Coconut Milk",      1,   "can",     "Thai Kitchen",          2.99,   730,  "Canned",     "Pantry"),

            // SPICES — Pantry
            ("Black Pepper",      1,   "jar",     nil,                     3.49,   1095, "Spices",     "Pantry"),
            ("Sea Salt",          1,   "jar",     "Morton",                1.99,   1825, "Spices",     "Pantry"),
            ("Cumin",             1,   "jar",     nil,                     2.99,   730,  "Spices",     "Pantry"),
            ("Paprika",           1,   "jar",     nil,                     2.49,   730,  "Spices",     "Pantry"),
        ]

        var map: [String: PantryItem] = [:]
        for (name, qty, unit, brand, price, days, catKey, locKey) in specs {
            let expDate = days.map { cal.date(byAdding: .day, value: $0, to: now)! }
            let item = PantryItem(
                name: name,
                quantity: qty,
                unit: unit,
                brand: brand,
                price: price,
                expirationDate: expDate,
                category: categories[catKey],
                location: locations[locKey]
            )
            context.insert(item)
            map[name] = item
        }
        return map
    }

    // MARK: - Recipes

    private static func seedRecipes(
        context: ModelContext,
        recipeCategories: [String: RecipeCategory],
        recipeTags: [String: RecipeTag],
        collections: [String: RecipeCollection],
        pantryItems: [String: PantryItem]
    ) {
        seedCarbonara(context: context, recipeCategories: recipeCategories, recipeTags: recipeTags, collections: collections)
        seedChickenStirFry(context: context, recipeCategories: recipeCategories, recipeTags: recipeTags, collections: collections)
        seedChocolateChipCookies(context: context, recipeCategories: recipeCategories, recipeTags: recipeTags, collections: collections)
        seedSpinachOmelet(context: context, recipeCategories: recipeCategories, recipeTags: recipeTags, collections: collections)
    }

    // ── Recipe 1: Spaghetti Carbonara ────────────────────────────────────────

    private static func seedCarbonara(
        context: ModelContext,
        recipeCategories: [String: RecipeCategory],
        recipeTags: [String: RecipeTag],
        collections: [String: RecipeCollection]
    ) {
        let recipe = Recipe(
            name: "Classic Spaghetti Carbonara",
            description: "A traditional Roman pasta dish made with eggs, Pecorino Romano, pancetta, and black pepper. Creamy, rich, and incredibly satisfying.",
            prepTime: 10,
            cookTime: 20,
            servings: 4,
            difficulty: .medium,
            rating: 4.5,
            isFavorite: true,
            notes: "The key is removing the pan from heat before adding the egg mixture — residual heat creates a silky sauce without scrambling."
        )
        context.insert(recipe)
        recipe.ingredients  = []
        recipe.instructions = []
        recipe.categories   = []
        recipe.tags         = []
        recipe.collections  = []
        recipe.cookingNotes = []

        for (name, qty, unit, order) in [
            ("Spaghetti",    400.0, "g",     0),
            ("Pancetta",     150.0, "g",     1),
            ("Eggs",           4.0, "count", 2),
            ("Parmesan",     100.0, "g",     3),
            ("Black Pepper",   2.0, "tsp",   4),
            ("Sea Salt",       1.0, "tbsp",  5),
        ] as [(String, Double, String, Int)] {
            let ing = RecipeIngredient(name: name, quantity: qty, unit: unit, sortOrder: order)
            context.insert(ing)
            recipe.ingredients?.append(ing)
        }

        for (i, (text, timer)) in [
            ("Bring a large pot of salted water to a boil. Cook spaghetti until al dente. Reserve 1 cup of pasta water before draining.", nil),
            ("While pasta cooks, fry the pancetta in a large skillet over medium heat until crispy, about 5 minutes. Remove from heat.", nil),
            ("In a bowl, whisk together eggs, grated Parmesan, and a generous amount of black pepper.", nil),
            ("Add the hot drained spaghetti to the pancetta skillet. Toss well so the pasta absorbs the fat.", nil),
            ("Remove the pan from heat and quickly pour the egg mixture over the pasta, tossing constantly and adding pasta water a splash at a time until silky.", 3),
            ("Serve immediately, topped with extra Parmesan and freshly cracked pepper.", nil),
        ].enumerated() as EnumeratedSequence<[(String, Int?)]> {
            let step = RecipeInstruction(stepNumber: i + 1, instruction: text, timerDuration: timer)
            context.insert(step)
            recipe.instructions?.append(step)
        }

        [recipeCategories["Dinner"], recipeCategories["Main Course"]].forEach {
            if let c = $0 { recipe.categories?.append(c) }
        }
        [recipeTags["Comfort Food"], recipeTags["Quick"]].forEach {
            if let t = $0 { recipe.tags?.append(t) }
        }
        if let col = collections["Weeknight Dinners"] { recipe.collections?.append(col) }

        let note = RecipeCookingNote(
            note: "Added a pinch of nutmeg to the egg mixture — unexpected but delicious!",
            rating: 5.0,
            authorName: "Loren"
        )
        context.insert(note)
        recipe.cookingNotes?.append(note)
    }

    // ── Recipe 2: Chicken Stir Fry ───────────────────────────────────────────

    private static func seedChickenStirFry(
        context: ModelContext,
        recipeCategories: [String: RecipeCategory],
        recipeTags: [String: RecipeTag],
        collections: [String: RecipeCollection]
    ) {
        let recipe = Recipe(
            name: "Chicken Stir Fry",
            description: "A quick and colorful stir fry with tender chicken, crisp vegetables, and a savory soy-ginger sauce. Ready in under 30 minutes.",
            prepTime: 15,
            cookTime: 12,
            servings: 4,
            difficulty: .easy,
            rating: 4.0,
            notes: "Slice the chicken thin across the grain for the most tender result."
        )
        context.insert(recipe)
        recipe.ingredients  = []
        recipe.instructions = []
        recipe.categories   = []
        recipe.tags         = []
        recipe.collections  = []
        recipe.cookingNotes = []

        for (name, qty, unit, order) in [
            ("Chicken Breast", 500.0, "g",      0),
            ("Bell Peppers",     2.0, "count",  1),
            ("Carrots",          2.0, "medium", 2),
            ("Garlic",           3.0, "cloves", 3),
            ("Soy Sauce",        3.0, "tbsp",   4),
            ("Olive Oil",        2.0, "tbsp",   5),
            ("Jasmine Rice",     2.0, "cups",   6),
        ] as [(String, Double, String, Int)] {
            let ing = RecipeIngredient(name: name, quantity: qty, unit: unit, sortOrder: order)
            context.insert(ing)
            recipe.ingredients?.append(ing)
        }

        for (i, (text, timer)) in [
            ("Cook the jasmine rice according to package instructions.", 18),
            ("Slice chicken breast thinly against the grain. Season with salt and pepper.", nil),
            ("Heat olive oil in a wok or large skillet over high heat until shimmering.", nil),
            ("Add chicken; stir-fry for 4–5 minutes until golden and cooked through. Remove and set aside.", 5),
            ("Add garlic, carrots, and bell peppers to the wok. Stir-fry for 3–4 minutes until just tender.", 4),
            ("Return chicken to the wok, add soy sauce, and toss everything together for 1 minute.", nil),
            ("Serve over steamed jasmine rice.", nil),
        ].enumerated() as EnumeratedSequence<[(String, Int?)]> {
            let step = RecipeInstruction(stepNumber: i + 1, instruction: text, timerDuration: timer)
            context.insert(step)
            recipe.instructions?.append(step)
        }

        [recipeCategories["Dinner"], recipeCategories["Main Course"]].forEach {
            if let c = $0 { recipe.categories?.append(c) }
        }
        [recipeTags["Quick"], recipeTags["Healthy"]].forEach {
            if let t = $0 { recipe.tags?.append(t) }
        }
        [collections["Weeknight Dinners"], collections["Meal Prep Favorites"]].forEach {
            if let col = $0 { recipe.collections?.append(col) }
        }
    }

    // ── Recipe 3: Chocolate Chip Cookies ─────────────────────────────────────

    private static func seedChocolateChipCookies(
        context: ModelContext,
        recipeCategories: [String: RecipeCategory],
        recipeTags: [String: RecipeTag],
        collections: [String: RecipeCollection]
    ) {
        let recipe = Recipe(
            name: "Chocolate Chip Cookies",
            description: "Classic soft and chewy cookies with crisp edges, packed with chocolate chips. The kind that make your whole kitchen smell amazing.",
            prepTime: 15,
            cookTime: 12,
            servings: 24,
            difficulty: .easy,
            rating: 5.0,
            isFavorite: true,
            notes: "Chill the dough for 30 minutes for thicker, chewier cookies."
        )
        context.insert(recipe)
        recipe.ingredients  = []
        recipe.instructions = []
        recipe.categories   = []
        recipe.tags         = []
        recipe.collections  = []
        recipe.cookingNotes = []

        for (name, qty, unit, order) in [
            ("All-Purpose Flour", 2.25, "cups",  0),
            ("Butter",            1.0,  "cup",   1),
            ("Sugar",             0.75, "cup",   2),
            ("Brown Sugar",       0.75, "cup",   3),
            ("Eggs",              2.0,  "count", 4),
            ("Vanilla Extract",   2.0,  "tsp",   5),
            ("Baking Soda",       1.0,  "tsp",   6),
            ("Sea Salt",          1.0,  "tsp",   7),
            ("Chocolate Chips",   2.0,  "cups",  8),
        ] as [(String, Double, String, Int)] {
            let ing = RecipeIngredient(name: name, quantity: qty, unit: unit, sortOrder: order)
            context.insert(ing)
            recipe.ingredients?.append(ing)
        }

        for (i, (text, timer)) in [
            ("Preheat oven to 375°F (190°C). Line two baking sheets with parchment paper.", nil),
            ("Beat butter with both sugars in a large bowl until light and fluffy, about 3 minutes.", 3),
            ("Add eggs one at a time, beating after each. Mix in vanilla extract.", nil),
            ("Whisk flour, baking soda, and salt together, then gradually stir into the butter mixture.", nil),
            ("Fold in chocolate chips until evenly distributed.", nil),
            ("Drop rounded tablespoons of dough onto prepared baking sheets, spacing 2 inches apart.", nil),
            ("Bake for 9–11 minutes until edges are golden. Centers will look slightly underdone — that's correct.", 10),
            ("Cool on the baking sheet for 5 minutes before transferring to a wire rack.", 5),
        ].enumerated() as EnumeratedSequence<[(String, Int?)]> {
            let step = RecipeInstruction(stepNumber: i + 1, instruction: text, timerDuration: timer)
            context.insert(step)
            recipe.instructions?.append(step)
        }

        if let cat = recipeCategories["Dessert"] { recipe.categories?.append(cat) }
        [recipeTags["Comfort Food"], recipeTags["Kid-Friendly"]].forEach {
            if let t = $0 { recipe.tags?.append(t) }
        }
        if let col = collections["Baking & Desserts"] { recipe.collections?.append(col) }

        let note = RecipeCookingNote(
            note: "Used dark chocolate chips and finished with flaky sea salt — absolutely next level.",
            rating: 5.0,
            authorName: "Loren"
        )
        context.insert(note)
        recipe.cookingNotes?.append(note)
    }

    // ── Recipe 4: Spinach & Cheddar Omelet ───────────────────────────────────

    private static func seedSpinachOmelet(
        context: ModelContext,
        recipeCategories: [String: RecipeCategory],
        recipeTags: [String: RecipeTag],
        collections: [String: RecipeCollection]
    ) {
        let recipe = Recipe(
            name: "Spinach & Cheddar Omelet",
            description: "A protein-rich breakfast omelet with wilted spinach and melted cheddar. Ready in under 10 minutes.",
            prepTime: 5,
            cookTime: 8,
            servings: 1,
            difficulty: .easy,
            rating: 4.0
        )
        context.insert(recipe)
        recipe.ingredients  = []
        recipe.instructions = []
        recipe.categories   = []
        recipe.tags         = []
        recipe.collections  = []
        recipe.cookingNotes = []

        for (name, qty, unit, order) in [
            ("Eggs",           3.0, "count", 0),
            ("Baby Spinach",   1.0, "cup",   1),
            ("Cheddar Cheese", 30.0, "g",    2),
            ("Butter",         1.0, "tsp",   3),
            ("Sea Salt",       1.0, "pinch", 4),
            ("Black Pepper",   1.0, "pinch", 5),
        ] as [(String, Double, String, Int)] {
            let ing = RecipeIngredient(name: name, quantity: qty, unit: unit, sortOrder: order)
            context.insert(ing)
            recipe.ingredients?.append(ing)
        }

        for (i, (text, timer)) in [
            ("Whisk eggs with a pinch of salt and pepper until smooth.", nil),
            ("Melt butter in a non-stick skillet over medium-low heat.", nil),
            ("Pour in eggs. As edges set, gently push them toward the center with a spatula.", 3),
            ("When mostly set but still slightly glossy on top, scatter spinach and cheddar over one half.", nil),
            ("Fold the omelet over the filling. Slide onto a plate and serve immediately.", nil),
        ].enumerated() as EnumeratedSequence<[(String, Int?)]> {
            let step = RecipeInstruction(stepNumber: i + 1, instruction: text, timerDuration: timer)
            context.insert(step)
            recipe.instructions?.append(step)
        }

        if let cat = recipeCategories["Breakfast"] { recipe.categories?.append(cat) }
        [recipeTags["Quick"], recipeTags["Healthy"], recipeTags["Vegetarian"]].forEach {
            if let t = $0 { recipe.tags?.append(t) }
        }
    }

    // MARK: - Shopping List

    private static func seedShoppingList(
        context: ModelContext,
        categories: [String: Category]
    ) {
        // (name, qty, unit, notes, isChecked, estimatedPrice, priority, categoryKey?)
        typealias ShopSpec = (String, Double, String, String?, Bool, Double?, Int, String?)
        let specs: [ShopSpec] = [
            ("Almond Milk",   1, "carton", "Unsweetened",  false, 3.99,  2, "Beverages"),
            ("Greek Yogurt",  2, "cups",   "Plain",        false, 2.49,  2, "Dairy"),
            ("Avocados",      3, "count",  "Ripe",         false, 1.50,  1, "Produce"),
            ("Blueberries",   1, "pint",   nil,            false, 4.99,  1, "Produce"),
            ("Salmon Fillet", 1, "lb",     "Wild-caught",  false, 12.99, 2, "Proteins"),
            ("Quinoa",        1, "bag",    nil,            false, 5.49,  1, "Grains"),
            ("Honey",         1, "jar",    "Raw",          false, 6.99,  0, "Condiments"),
            ("Pasta Sauce",   2, "jars",   "Marinara",     true,  3.49,  1, "Canned"),
            ("Dish Soap",     1, "bottle", nil,            true,  2.99,  0, nil),
            ("Paper Towels",  2, "rolls",  nil,            true,  4.99,  0, nil),
        ]
        for (name, qty, unit, notes, checked, price, priority, catKey) in specs {
            let item = ShoppingListItem(
                name: name,
                quantity: qty,
                unit: unit,
                notes: notes,
                isChecked: checked,
                estimatedPrice: price,
                priority: priority,
                category: catKey.flatMap { categories[$0] }
            )
            context.insert(item)
        }
    }

    // MARK: - Receipts

    private static func seedReceipts(context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        // Receipt 1 — recent Whole Foods trip (2 days ago)
        let r1 = Receipt(
            storeName: "Whole Foods Market",
            purchaseDate: cal.date(byAdding: .day, value: -2, to: now)!,
            totalAmount: 67.43
        )
        context.insert(r1)
        r1.items = []
        for (name, qty, unit, price) in [
            ("Organic Valley Whole Milk",   1.0, "gallon",  6.49),
            ("Happy Egg Eggs",              1.0, "dozen",   5.49),
            ("Tillamook Cheddar",           1.0, "block",   4.99),
            ("Earthbound Farm Spinach",     1.0, "bag",     3.99),
            ("Ghirardelli Chocolate Chips", 1.0, "bag",     4.49),
            ("Blue Bottle Coffee",          1.0, "bag",    16.99),
            ("Tropicana Orange Juice",      1.0, "carton",  4.29),
            ("BelGioioso Parmesan",         1.0, "wedge",   5.49),
            ("Huy Fong Sriracha",           1.0, "bottle",  3.49),
            ("Heavy Cream",                 1.0, "pint",    2.99),
        ] as [(String, Double, String, Double)] {
            let ri = ReceiptItem(name: name, quantity: qty, unit: unit, price: price, isAddedToPantry: true)
            context.insert(ri)
            r1.items?.append(ri)
        }

        // Receipt 2 — Trader Joe's last week (9 days ago)
        let r2 = Receipt(
            storeName: "Trader Joe's",
            purchaseDate: cal.date(byAdding: .day, value: -9, to: now)!,
            totalAmount: 42.18
        )
        context.insert(r2)
        r2.items = []
        for (name, qty, unit, price) in [
            ("Barilla Spaghetti",    2.0, "bags",   1.89),
            ("Lundberg Jasmine Rice",1.0, "bag",    3.49),
            ("Kikkoman Soy Sauce",   1.0, "bottle", 3.29),
            ("Chicken Breast",       2.0, "lbs",    8.99),
            ("Muir Glen Diced Tomatoes", 3.0, "cans", 2.49),
            ("Thai Kitchen Coconut Milk", 2.0, "cans", 2.99),
            ("Morton Sea Salt",      1.0, "box",    1.99),
        ] as [(String, Double, String, Double)] {
            let ri = ReceiptItem(name: name, quantity: qty, unit: unit, price: price, isAddedToPantry: true)
            context.insert(ri)
            r2.items?.append(ri)
        }

        // Receipt 3 — Safeway 3 weeks ago (21 days ago), items not yet added to pantry
        let r3 = Receipt(
            storeName: "Safeway",
            purchaseDate: cal.date(byAdding: .day, value: -21, to: now)!,
            totalAmount: 28.55
        )
        context.insert(r3)
        r3.items = []
        for (name, qty, unit, price) in [
            ("Kerrygold Butter",          2.0, "sticks",  3.49),
            ("King Arthur Flour",         1.0, "bag",     4.79),
            ("Domino Sugar",              1.0, "bag",     3.49),
            ("Arm & Hammer Baking Soda",  1.0, "box",     1.49),
            ("Nielsen-Massey Vanilla",    1.0, "bottle",  8.99),
        ] as [(String, Double, String, Double)] {
            let ri = ReceiptItem(name: name, quantity: qty, unit: unit, price: price, isAddedToPantry: false)
            context.insert(ri)
            r3.items?.append(ri)
        }
    }
}
