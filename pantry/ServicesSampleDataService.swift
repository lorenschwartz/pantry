//
//  SampleDataService.swift
//  pantry
//
//  Seeds the on-device store with realistic demo data so every feature
//  (expiring items, low stock, recipes, shopping suggestions, insights) has
//  something to show immediately after install.
//

import Foundation
import SwiftData

class SampleDataService {

    // MARK: - Public API

    /// Returns true when at least one PantryItem already exists in the store.
    static func hasExistingData(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<PantryItem>()
        return (try? context.fetchCount(descriptor) ?? 0) ?? 0 > 0
    }

    /// Inserts categories, locations, pantry items, recipes, and shopping list entries.
    /// Returns the total number of records inserted.
    @discardableResult
    static func loadSampleData(into context: ModelContext) -> Int {
        var count = 0
        let cal = Calendar.current
        func days(_ n: Int) -> Date? { cal.date(byAdding: .day, value: n, to: Date()) }
        func months(_ n: Int) -> Date? { cal.date(byAdding: .month, value: n, to: Date()) }

        // MARK: Categories
        let cats = Category.defaultCategories
        cats.forEach { context.insert($0) }
        count += cats.count

        let produce    = cats[0]
        let dairy      = cats[1]
        let proteins   = cats[2]
        let grains     = cats[3]
        let spices     = cats[4]
        let condiments = cats[5]
        let beverages  = cats[6]
        let snacks     = cats[7]
        let frozen     = cats[8]
        let canned     = cats[9]
        let baking     = cats[10]

        // MARK: Locations
        let locs = StorageLocation.defaultLocations
        locs.forEach { context.insert($0) }
        count += locs.count

        let pantryLoc = locs[0]   // Pantry
        let fridge    = locs[1]   // Refrigerator
        let freezer   = locs[2]   // Freezer
        let counter   = locs[3]   // Counter

        // MARK: Pantry items
        // Covers: expiring soon, already expired, low stock, normal stock, no expiry.
        let pantryItems: [PantryItem] = [
            build("Whole Milk",       qty: 0.5,  unit: "gallon",    cat: dairy,      loc: fridge,    price: 4.99,  exp: days(4)),
            build("Eggs",             qty: 12,   unit: "count",     cat: proteins,   loc: fridge,    price: 5.99,  exp: days(14)),
            build("Sourdough Bread",  qty: 1,    unit: "loaf",      cat: grains,     loc: counter,   price: 4.50,  exp: days(2)),
            build("Cheddar Cheese",   qty: 0.5,  unit: "lb",        cat: dairy,      loc: fridge,    price: 6.99,  exp: days(1)),
            build("Chicken Breast",   qty: 2,    unit: "lb",        cat: proteins,   loc: fridge,    price: 8.99,  exp: days(2)),
            build("Baby Spinach",     qty: 1,    unit: "bag",       cat: produce,    loc: fridge,    price: 3.99,  exp: days(-1)),  // expired
            build("Bananas",          qty: 5,    unit: "count",     cat: produce,    loc: counter,   price: 1.29,  exp: days(4)),
            build("Greek Yogurt",     qty: 2,    unit: "container", cat: dairy,      loc: fridge,    price: 5.49,  exp: days(7)),
            build("Pasta",            qty: 3,    unit: "box",       cat: grains,     loc: pantryLoc, price: 2.49,  exp: months(18)),
            build("Rice",             qty: 5,    unit: "lb",        cat: grains,     loc: pantryLoc, price: 5.99,  exp: months(24)),
            build("Salt",             qty: 1,    unit: "container", cat: spices,     loc: pantryLoc, price: 1.99),
            build("Black Pepper",     qty: 0.5,  unit: "jar",       cat: spices,     loc: pantryLoc, price: 3.49),
            build("Coffee",           qty: 0.5,  unit: "bag",       cat: beverages,  loc: pantryLoc, price: 12.99, exp: months(6)),
            build("Orange Juice",     qty: 1,    unit: "carton",    cat: beverages,  loc: fridge,    price: 4.99,  exp: days(7)),
            build("Butter",           qty: 0.5,  unit: "lb",        cat: dairy,      loc: fridge,    price: 4.49,  exp: days(21)),
            build("Canned Tomatoes",  qty: 4,    unit: "can",       cat: canned,     loc: pantryLoc, price: 1.99,  exp: months(24)),
            build("Frozen Peas",      qty: 2,    unit: "bag",       cat: frozen,     loc: freezer,   price: 2.99,  exp: months(8)),
            build("Almonds",          qty: 2,    unit: "bag",       cat: snacks,     loc: pantryLoc, price: 8.99,  exp: months(12)),
            build("Olive Oil",        qty: 1,    unit: "bottle",    cat: condiments, loc: pantryLoc, price: 12.99, exp: months(12)),
            build("Soy Sauce",        qty: 1,    unit: "bottle",    cat: condiments, loc: pantryLoc, price: 3.99,  exp: months(24)),
            build("Flour",            qty: 2,    unit: "lb",        cat: baking,     loc: pantryLoc, price: 3.99,  exp: months(12)),
            build("Sugar",            qty: 1,    unit: "lb",        cat: baking,     loc: pantryLoc, price: 4.99,  exp: months(24)),
            build("Garlic",           qty: 3,    unit: "cloves",    cat: produce,    loc: counter,   price: 0.99,  exp: days(21)),
            build("Lemon",            qty: 2,    unit: "count",     cat: produce,    loc: fridge,    price: 0.79,  exp: days(10)),
            build("Heavy Cream",      qty: 0.5,  unit: "cup",       cat: dairy,      loc: fridge,    price: 3.49,  exp: days(5)),
        ]
        pantryItems.forEach { context.insert($0) }
        count += pantryItems.count

        // MARK: Recipes (with ingredients + instructions)
        let recipesData = [
            makeSpaghettCarbonara(),
            makeChickenStirFry(),
            makeScrambledEggs(),
            makeChocolateChipCookies(),
        ]
        for (recipe, ingredients, instructions) in recipesData {
            context.insert(recipe)
            ingredients.forEach { context.insert($0) }
            instructions.forEach { context.insert($0) }
            count += 1 + ingredients.count + instructions.count
        }

        // MARK: Shopping list (reflects current low-stock items)
        let shoppingItems: [ShoppingListItem] = [
            ShoppingListItem(name: "Whole Milk",   quantity: 1, unit: "gallon",    estimatedPrice: 4.99, priority: 2, category: dairy),
            ShoppingListItem(name: "Coffee",       quantity: 1, unit: "bag",       estimatedPrice: 12.99, priority: 2, category: beverages),
            ShoppingListItem(name: "Sourdough Bread", quantity: 1, unit: "loaf",   estimatedPrice: 4.50, priority: 2, category: grains),
            ShoppingListItem(name: "Butter",       quantity: 1, unit: "lb",        estimatedPrice: 4.49, priority: 1, category: dairy),
            ShoppingListItem(name: "Black Pepper", quantity: 1, unit: "jar",       estimatedPrice: 3.49, priority: 1, category: spices),
            ShoppingListItem(name: "Eggs",         quantity: 12, unit: "count",    estimatedPrice: 5.99, priority: 1, category: proteins,  isChecked: true),
        ]
        shoppingItems.forEach { context.insert($0) }
        count += shoppingItems.count

        try? context.save()
        return count
    }

    /// Deletes every record from the store across all model types.
    static func clearAllData(from context: ModelContext) {
        let modelTypes: [any PersistentModel.Type] = [
            PantryItem.self,
            ShoppingListItem.self,
            RecipeIngredient.self,
            RecipeInstruction.self,
            RecipeCookingNote.self,
            Recipe.self,
            RecipeCategory.self,
            RecipeTag.self,
            RecipeCollection.self,
            Receipt.self,
            ReceiptItem.self,
            BarcodeMapping.self,
            Category.self,
            StorageLocation.self,
        ]
        for type_ in modelTypes {
            try? context.delete(model: type_)
        }
        try? context.save()
    }

    // MARK: - Private helpers

    private static func build(
        _ name: String,
        qty: Double,
        unit: String,
        cat: Category,
        loc: StorageLocation,
        price: Double,
        exp: Date? = nil
    ) -> PantryItem {
        let item = PantryItem(
            name: name,
            quantity: qty,
            unit: unit,
            price: price,
            expirationDate: exp,
            category: cat,
            location: loc
        )
        return item
    }

    // MARK: - Sample recipes

    private static func makeSpaghettCarbonara() -> (Recipe, [RecipeIngredient], [RecipeInstruction]) {
        let recipe = Recipe(
            name: "Spaghetti Carbonara",
            description: "Classic Italian pasta with eggs, cheese, and a silky sauce",
            prepTime: 10,
            cookTime: 20,
            servings: 4,
            difficulty: .medium,
            rating: 4.5,
            isFavorite: true
        )
        let ingredients = [
            RecipeIngredient(name: "Pasta",         quantity: 400, unit: "g",   sortOrder: 0),
            RecipeIngredient(name: "Eggs",           quantity: 4,   unit: "count", sortOrder: 1),
            RecipeIngredient(name: "Cheddar Cheese", quantity: 100, unit: "g",   sortOrder: 2),
            RecipeIngredient(name: "Olive Oil",      quantity: 2,   unit: "tbsp", sortOrder: 3),
            RecipeIngredient(name: "Salt",           quantity: 1,   unit: "tsp",  sortOrder: 4),
            RecipeIngredient(name: "Black Pepper",   quantity: 0.5, unit: "tsp",  sortOrder: 5),
        ]
        let instructions = [
            RecipeInstruction(stepNumber: 1, instruction: "Bring a large pot of salted water to a boil. Cook pasta until al dente according to package directions.", timerDuration: 10),
            RecipeInstruction(stepNumber: 2, instruction: "Whisk eggs and grated cheese together in a bowl until smooth."),
            RecipeInstruction(stepNumber: 3, instruction: "Reserve 1 cup of pasta cooking water, then drain the pasta."),
            RecipeInstruction(stepNumber: 4, instruction: "Remove the pot from heat. Add pasta to the egg mixture, tossing quickly. Add pasta water a splash at a time until the sauce coats the noodles."),
            RecipeInstruction(stepNumber: 5, instruction: "Season generously with black pepper and salt. Serve immediately."),
        ]
        link(recipe: recipe, ingredients: ingredients, instructions: instructions)
        return (recipe, ingredients, instructions)
    }

    private static func makeChickenStirFry() -> (Recipe, [RecipeIngredient], [RecipeInstruction]) {
        let recipe = Recipe(
            name: "Chicken Stir Fry",
            description: "Quick and healthy one-pan meal with tender chicken and crisp vegetables",
            prepTime: 15,
            cookTime: 10,
            servings: 4,
            difficulty: .easy,
            rating: 4.0
        )
        let ingredients = [
            RecipeIngredient(name: "Chicken Breast", quantity: 2,   unit: "lb",   sortOrder: 0),
            RecipeIngredient(name: "Soy Sauce",      quantity: 3,   unit: "tbsp", sortOrder: 1),
            RecipeIngredient(name: "Garlic",          quantity: 3,   unit: "cloves", sortOrder: 2),
            RecipeIngredient(name: "Olive Oil",       quantity: 2,   unit: "tbsp", sortOrder: 3),
            RecipeIngredient(name: "Frozen Peas",     quantity: 1,   unit: "cup",  sortOrder: 4),
            RecipeIngredient(name: "Rice",            quantity: 2,   unit: "cup",  sortOrder: 5),
        ]
        let instructions = [
            RecipeInstruction(stepNumber: 1, instruction: "Slice chicken into thin strips. Mince the garlic."),
            RecipeInstruction(stepNumber: 2, instruction: "Cook rice according to package directions."),
            RecipeInstruction(stepNumber: 3, instruction: "Heat oil in a wok or large skillet over high heat. Add garlic and cook 30 seconds."),
            RecipeInstruction(stepNumber: 4, instruction: "Add chicken and stir fry until cooked through, about 5–6 minutes.", timerDuration: 6),
            RecipeInstruction(stepNumber: 5, instruction: "Add frozen peas and soy sauce. Toss everything together and cook 2 more minutes.", timerDuration: 2),
            RecipeInstruction(stepNumber: 6, instruction: "Serve over rice."),
        ]
        link(recipe: recipe, ingredients: ingredients, instructions: instructions)
        return (recipe, ingredients, instructions)
    }

    private static func makeScrambledEggs() -> (Recipe, [RecipeIngredient], [RecipeInstruction]) {
        let recipe = Recipe(
            name: "Creamy Scrambled Eggs",
            description: "Soft, buttery scrambled eggs — the only breakfast recipe you need",
            prepTime: 2,
            cookTime: 5,
            servings: 2,
            difficulty: .easy,
            rating: 4.8,
            isFavorite: true
        )
        let ingredients = [
            RecipeIngredient(name: "Eggs",        quantity: 4,   unit: "count", sortOrder: 0),
            RecipeIngredient(name: "Butter",      quantity: 1,   unit: "tbsp",  sortOrder: 1),
            RecipeIngredient(name: "Heavy Cream", quantity: 2,   unit: "tbsp",  sortOrder: 2),
            RecipeIngredient(name: "Salt",        quantity: 0.25,unit: "tsp",   sortOrder: 3),
            RecipeIngredient(name: "Black Pepper",quantity: 0.25,unit: "tsp",   sortOrder: 4),
        ]
        let instructions = [
            RecipeInstruction(stepNumber: 1, instruction: "Whisk eggs, cream, salt, and pepper in a bowl."),
            RecipeInstruction(stepNumber: 2, instruction: "Melt butter in a non-stick pan over low heat."),
            RecipeInstruction(stepNumber: 3, instruction: "Pour in egg mixture. Stir gently and continuously with a silicone spatula, pulling the eggs from the edges to the centre."),
            RecipeInstruction(stepNumber: 4, instruction: "Remove from heat while still slightly underdone — they will finish cooking off the heat. Serve immediately."),
        ]
        link(recipe: recipe, ingredients: ingredients, instructions: instructions)
        return (recipe, ingredients, instructions)
    }

    private static func makeChocolateChipCookies() -> (Recipe, [RecipeIngredient], [RecipeInstruction]) {
        let recipe = Recipe(
            name: "Chocolate Chip Cookies",
            description: "Thick, chewy, bakery-style cookies with gooey chocolate chips",
            prepTime: 15,
            cookTime: 12,
            servings: 24,
            difficulty: .easy,
            rating: 5.0,
            isFavorite: true
        )
        let ingredients = [
            RecipeIngredient(name: "Flour",   quantity: 2.25, unit: "cup",  sortOrder: 0),
            RecipeIngredient(name: "Butter",  quantity: 1,    unit: "cup",  sortOrder: 1),
            RecipeIngredient(name: "Sugar",   quantity: 0.75, unit: "cup",  sortOrder: 2),
            RecipeIngredient(name: "Eggs",    quantity: 2,    unit: "count",sortOrder: 3),
            RecipeIngredient(name: "Salt",    quantity: 1,    unit: "tsp",  sortOrder: 4),
        ]
        let instructions = [
            RecipeInstruction(stepNumber: 1, instruction: "Preheat oven to 375 °F (190 °C)."),
            RecipeInstruction(stepNumber: 2, instruction: "Beat butter and both sugars until light and fluffy. Add eggs one at a time."),
            RecipeInstruction(stepNumber: 3, instruction: "Mix in flour and salt until just combined. Fold in chocolate chips."),
            RecipeInstruction(stepNumber: 4, instruction: "Drop rounded tablespoons onto ungreased baking sheets."),
            RecipeInstruction(stepNumber: 5, instruction: "Bake 9–11 minutes until edges are golden. Cool on baking sheet for 2 minutes before transferring.", timerDuration: 11),
        ]
        link(recipe: recipe, ingredients: ingredients, instructions: instructions)
        return (recipe, ingredients, instructions)
    }

    private static func link(
        recipe: Recipe,
        ingredients: [RecipeIngredient],
        instructions: [RecipeInstruction]
    ) {
        ingredients.forEach { $0.recipe = recipe }
        instructions.forEach { $0.recipe = recipe }
        recipe.ingredients = ingredients
        recipe.instructions = instructions
    }
}
