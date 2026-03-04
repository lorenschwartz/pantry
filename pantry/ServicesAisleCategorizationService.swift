//
//  AisleCategorizationService.swift
//  pantry
//
//  Automatically categorizes shopping list items into grocery store aisles
//  based on keyword matching against item names.
//

import Foundation
import SwiftData

/// Matches shopping list item names to grocery store aisles (Category names)
/// using a word-by-word keyword lookup. First matching word wins.
enum AisleCategorizationService {

    // MARK: - Keyword → Aisle Name Map

    /// Maps lowercase single-word tokens to a Category name.
    /// Word-by-word matching means each key must be a single token (no spaces).
    /// For compound items like "baking soda", the first recognized word ("baking") wins.
    static let keywordMap: [String: String] = [

        // ── Produce ──────────────────────────────────────────────────────────
        "apple": "Produce",          "apples": "Produce",
        "banana": "Produce",         "bananas": "Produce",
        "orange": "Produce",         "oranges": "Produce",
        "lemon": "Produce",          "lemons": "Produce",
        "lime": "Produce",           "limes": "Produce",
        "grape": "Produce",          "grapes": "Produce",
        "strawberry": "Produce",     "strawberries": "Produce",
        "blueberry": "Produce",      "blueberries": "Produce",
        "raspberry": "Produce",      "raspberries": "Produce",
        "blackberry": "Produce",     "blackberries": "Produce",
        "cherry": "Produce",         "cherries": "Produce",
        "peach": "Produce",          "peaches": "Produce",
        "plum": "Produce",           "plums": "Produce",
        "nectarine": "Produce",      "nectarines": "Produce",
        "apricot": "Produce",        "apricots": "Produce",
        "mango": "Produce",          "mangoes": "Produce",
        "pineapple": "Produce",      "pineapples": "Produce",
        "watermelon": "Produce",     "watermelons": "Produce",
        "melon": "Produce",          "melons": "Produce",
        "cantaloupe": "Produce",
        "avocado": "Produce",        "avocados": "Produce",
        "tomato": "Produce",         "tomatoes": "Produce",
        "potato": "Produce",         "potatoes": "Produce",
        "onion": "Produce",          "onions": "Produce",
        "garlic": "Produce",
        "carrot": "Produce",         "carrots": "Produce",
        "celery": "Produce",
        "cucumber": "Produce",       "cucumbers": "Produce",
        "lettuce": "Produce",
        "spinach": "Produce",
        "kale": "Produce",
        "broccoli": "Produce",
        "cauliflower": "Produce",
        "peppers": "Produce",
        "jalapeño": "Produce",       "jalapeno": "Produce",       "jalapeños": "Produce",
        "zucchini": "Produce",
        "squash": "Produce",
        "mushroom": "Produce",       "mushrooms": "Produce",
        "cilantro": "Produce",
        "parsley": "Produce",
        "basil": "Produce",
        "ginger": "Produce",
        "cabbage": "Produce",
        "beet": "Produce",           "beets": "Produce",
        "radish": "Produce",         "radishes": "Produce",
        "artichoke": "Produce",      "artichokes": "Produce",
        "asparagus": "Produce",
        "corn": "Produce",
        "eggplant": "Produce",
        "arugula": "Produce",
        "chard": "Produce",
        "turnip": "Produce",         "turnips": "Produce",
        "scallion": "Produce",       "scallions": "Produce",
        "leek": "Produce",           "leeks": "Produce",
        "shallot": "Produce",        "shallots": "Produce",
        "fennel": "Produce",
        "chive": "Produce",          "chives": "Produce",
        "veggie": "Produce",         "veggies": "Produce",
        "herb": "Produce",           "herbs": "Produce",

        // ── Dairy ─────────────────────────────────────────────────────────────
        "milk": "Dairy",
        "cream": "Dairy",
        "butter": "Dairy",
        "cheese": "Dairy",
        "yogurt": "Dairy",
        "cheddar": "Dairy",
        "mozzarella": "Dairy",
        "parmesan": "Dairy",
        "brie": "Dairy",
        "feta": "Dairy",
        "ricotta": "Dairy",
        "provolone": "Dairy",
        "gouda": "Dairy",
        "kefir": "Dairy",
        "ghee": "Dairy",
        "creamer": "Dairy",

        // ── Proteins ──────────────────────────────────────────────────────────
        "chicken": "Proteins",
        "beef": "Proteins",
        "pork": "Proteins",
        "lamb": "Proteins",
        "turkey": "Proteins",
        "salmon": "Proteins",
        "tuna": "Proteins",
        "shrimp": "Proteins",
        "bacon": "Proteins",
        "sausage": "Proteins",
        "steak": "Proteins",
        "ham": "Proteins",
        "duck": "Proteins",
        "veal": "Proteins",
        "lobster": "Proteins",
        "crab": "Proteins",
        "clam": "Proteins",          "clams": "Proteins",
        "oyster": "Proteins",        "oysters": "Proteins",
        "mussel": "Proteins",        "mussels": "Proteins",
        "scallop": "Proteins",       "scallops": "Proteins",
        "egg": "Proteins",           "eggs": "Proteins",
        "tofu": "Proteins",
        "tempeh": "Proteins",
        "sardine": "Proteins",       "sardines": "Proteins",
        "anchovy": "Proteins",       "anchovies": "Proteins",
        "tilapia": "Proteins",
        "cod": "Proteins",
        "halibut": "Proteins",
        "trout": "Proteins",
        "chorizo": "Proteins",
        "prosciutto": "Proteins",
        "pepperoni": "Proteins",
        "salami": "Proteins",
        "meat": "Proteins",
        "fish": "Proteins",
        "seafood": "Proteins",
        "ribs": "Proteins",
        "brisket": "Proteins",
        "ground": "Proteins",        // ground beef, ground turkey, ground pork

        // ── Grains ────────────────────────────────────────────────────────────
        "bread": "Grains",
        "rice": "Grains",
        "pasta": "Grains",
        "oat": "Grains",             "oats": "Grains",
        "cereal": "Grains",
        "flour": "Grains",
        "tortilla": "Grains",        "tortillas": "Grains",
        "bagel": "Grains",           "bagels": "Grains",
        "noodle": "Grains",          "noodles": "Grains",
        "couscous": "Grains",
        "quinoa": "Grains",
        "barley": "Grains",
        "pita": "Grains",
        "panko": "Grains",
        "breadcrumb": "Grains",      "breadcrumbs": "Grains",
        "bun": "Grains",             "buns": "Grains",
        "roll": "Grains",            "rolls": "Grains",
        "croissant": "Grains",       "croissants": "Grains",
        "muffin": "Grains",          "muffins": "Grains",
        "waffle": "Grains",          "waffles": "Grains",
        "granola": "Grains",
        "wrap": "Grains",            "wraps": "Grains",
        "spaghetti": "Grains",
        "penne": "Grains",
        "fettuccine": "Grains",
        "lasagna": "Grains",
        "linguine": "Grains",
        "orzo": "Grains",
        "grits": "Grains",
        "cornmeal": "Grains",

        // ── Spices ────────────────────────────────────────────────────────────
        "salt": "Spices",
        "pepper": "Spices",          // singular = black pepper (spice)
        "cinnamon": "Spices",
        "cumin": "Spices",
        "turmeric": "Spices",
        "paprika": "Spices",
        "oregano": "Spices",
        "thyme": "Spices",
        "rosemary": "Spices",
        "cayenne": "Spices",
        "cardamom": "Spices",
        "nutmeg": "Spices",
        "cloves": "Spices",
        "allspice": "Spices",
        "curry": "Spices",
        "saffron": "Spices",
        "coriander": "Spices",
        "marjoram": "Spices",
        "sage": "Spices",
        "dill": "Spices",
        "tarragon": "Spices",
        "mint": "Spices",
        "bay": "Spices",
        "chili": "Spices",
        "seasoning": "Spices",
        "spice": "Spices",           "spices": "Spices",

        // ── Condiments ────────────────────────────────────────────────────────
        "ketchup": "Condiments",
        "mustard": "Condiments",
        "mayonnaise": "Condiments",
        "mayo": "Condiments",
        "salsa": "Condiments",
        "oil": "Condiments",
        "vinegar": "Condiments",
        "ranch": "Condiments",
        "hummus": "Condiments",
        "guacamole": "Condiments",
        "jam": "Condiments",
        "jelly": "Condiments",
        "honey": "Condiments",
        "tahini": "Condiments",
        "sriracha": "Condiments",
        "relish": "Condiments",
        "pickle": "Condiments",      "pickles": "Condiments",
        "capers": "Condiments",
        "teriyaki": "Condiments",
        "hoisin": "Condiments",
        "sauce": "Condiments",
        "dressing": "Condiments",
        "aioli": "Condiments",
        "pesto": "Condiments",
        "syrup": "Condiments",
        "maple": "Condiments",
        "olives": "Condiments",
        "spread": "Condiments",
        "marmalade": "Condiments",

        // ── Beverages ─────────────────────────────────────────────────────────
        "water": "Beverages",
        "juice": "Beverages",
        "coffee": "Beverages",
        "tea": "Beverages",
        "beer": "Beverages",
        "wine": "Beverages",
        "soda": "Beverages",
        "lemonade": "Beverages",
        "kombucha": "Beverages",
        "smoothie": "Beverages",
        "broth": "Beverages",
        "stock": "Beverages",
        "drink": "Beverages",        "drinks": "Beverages",
        "sparkling": "Beverages",
        "cider": "Beverages",
        "espresso": "Beverages",
        "whiskey": "Beverages",
        "vodka": "Beverages",
        "rum": "Beverages",
        "tequila": "Beverages",
        "bourbon": "Beverages",
        "gin": "Beverages",

        // ── Snacks ────────────────────────────────────────────────────────────
        "chip": "Snacks",            "chips": "Snacks",
        "popcorn": "Snacks",
        "cookie": "Snacks",          "cookies": "Snacks",
        "candy": "Snacks",
        "chocolate": "Snacks",
        "nut": "Snacks",             "nuts": "Snacks",
        "almonds": "Snacks",
        "cashew": "Snacks",          "cashews": "Snacks",
        "walnut": "Snacks",          "walnuts": "Snacks",
        "pistachio": "Snacks",       "pistachios": "Snacks",
        "peanuts": "Snacks",
        "raisin": "Snacks",          "raisins": "Snacks",
        "jerky": "Snacks",
        "gummy": "Snacks",           "gummies": "Snacks",
        "pretzel": "Snacks",         "pretzels": "Snacks",
        "cracker": "Snacks",         "crackers": "Snacks",
        "sunflower": "Snacks",
        "trail": "Snacks",

        // ── Frozen ────────────────────────────────────────────────────────────
        "frozen": "Frozen",
        "edamame": "Frozen",
        "popsicle": "Frozen",        "popsicles": "Frozen",
        "sorbet": "Frozen",
        "gelato": "Frozen",
        "ice": "Frozen",

        // ── Canned ────────────────────────────────────────────────────────────
        "canned": "Canned",
        "soup": "Canned",            "soups": "Canned",
        "beans": "Canned",
        "chickpea": "Canned",        "chickpeas": "Canned",
        "lentil": "Canned",          "lentils": "Canned",

        // ── Baking ────────────────────────────────────────────────────────────
        "sugar": "Baking",
        "yeast": "Baking",
        "cocoa": "Baking",
        "cornstarch": "Baking",
        "molasses": "Baking",
        "sprinkles": "Baking",
        "gelatin": "Baking",
        "shortening": "Baking",
        "baking": "Baking",
        "vanilla": "Baking",
        "confectioner": "Baking",
    ]

    // MARK: - Public API

    /// Returns the grocery store aisle name for `itemName`, or `nil` if unrecognized.
    ///
    /// Matching strategy (case-insensitive, word-by-word, first match wins):
    /// 1. Tokenize the item name on whitespace and punctuation.
    /// 2. Check each token against `keywordMap` in order.
    /// 3. Return the aisle name of the first match found.
    static func suggestAisleName(for itemName: String) -> String? {
        let tokens = itemName
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        for token in tokens {
            if let aisle = keywordMap[token] { return aisle }
        }
        return nil
    }

    /// Returns the `Category` from `categories` whose name matches the suggested
    /// aisle for `itemName`, or `nil` if no match is found.
    static func suggestCategory(for itemName: String, from categories: [Category]) -> Category? {
        guard let aisleName = suggestAisleName(for: itemName) else { return nil }
        return categories.first {
            $0.name.localizedCaseInsensitiveCompare(aisleName) == .orderedSame
        }
    }

    /// Assigns a suggested `Category` to every `ShoppingListItem` that has no
    /// category set. Items already categorized (manually by the user) are left
    /// unchanged.
    static func categorizeUncategorized(items: [ShoppingListItem], categories: [Category]) {
        for item in items where item.category == nil {
            item.category = suggestCategory(for: item.name, from: categories)
        }
    }
}
