//
//  Recipe.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Recipe {
    var id: UUID
    var name: String
    var recipeDescription: String?
    var imageData: Data?
    var prepTime: Int // in minutes
    var cookTime: Int // in minutes
    var servings: Int
    var difficulty: RecipeDifficulty
    var rating: Double? // 0-5
    var isFavorite: Bool
    var createdDate: Date
    var modifiedDate: Date
    var lastCookedDate: Date?
    var timesCookedCount: Int
    var notes: String? // User's personal notes
    var sourceURL: String? // If imported from web
    var addedBy: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var ingredients: [RecipeIngredient]?
    
    @Relationship(deleteRule: .cascade)
    var instructions: [RecipeInstruction]?
    
    @Relationship(deleteRule: .nullify)
    var categories: [RecipeCategory]?
    
    @Relationship(deleteRule: .nullify)
    var tags: [RecipeTag]?
    
    @Relationship(deleteRule: .cascade)
    var cookingNotes: [RecipeCookingNote]?
    
    @Relationship(deleteRule: .nullify)
    var collections: [RecipeCollection]?
    
    // Computed properties
    var totalTime: Int {
        prepTime + cookTime
    }
    
    var ingredientCount: Int {
        ingredients?.count ?? 0
    }
    
    var stepCount: Int {
        instructions?.count ?? 0
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        imageData: Data? = nil,
        prepTime: Int = 0,
        cookTime: Int = 0,
        servings: Int = 4,
        difficulty: RecipeDifficulty = .medium,
        rating: Double? = nil,
        isFavorite: Bool = false,
        notes: String? = nil,
        sourceURL: String? = nil,
        addedBy: String? = nil
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = description
        self.imageData = imageData
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.servings = servings
        self.difficulty = difficulty
        self.rating = rating
        self.isFavorite = isFavorite
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.timesCookedCount = 0
        self.notes = notes
        self.sourceURL = sourceURL
        self.addedBy = addedBy
    }
    
    func markAsCooked() {
        lastCookedDate = Date()
        timesCookedCount += 1
        modifiedDate = Date()
    }
    
    func scaleServings(to newServings: Int) -> Double {
        guard servings > 0 else { return 1.0 }
        return Double(newServings) / Double(servings)
    }
}

// MARK: - Recipe Difficulty
enum RecipeDifficulty: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var icon: String {
        switch self {
        case .easy: return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Recipe Ingredient
@Model
final class RecipeIngredient {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var notes: String? // e.g., "chopped", "room temperature"
    var isOptional: Bool
    var sortOrder: Int
    
    // Relationships
    var recipe: Recipe?
    
    // Optional link to pantry item for inventory matching
    var pantryItemID: UUID?
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        notes: String? = nil,
        isOptional: Bool = false,
        sortOrder: Int = 0,
        pantryItemID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.isOptional = isOptional
        self.sortOrder = sortOrder
        self.pantryItemID = pantryItemID
    }
    
    func scaled(by factor: Double) -> RecipeIngredient {
        RecipeIngredient(
            name: name,
            quantity: quantity * factor,
            unit: unit,
            notes: notes,
            isOptional: isOptional,
            sortOrder: sortOrder,
            pantryItemID: pantryItemID
        )
    }
}

// MARK: - Recipe Instruction
@Model
final class RecipeInstruction {
    var id: UUID
    var stepNumber: Int
    var instruction: String
    var timerDuration: Int? // in minutes, if this step needs a timer
    var imageData: Data? // Optional image for this step
    
    // Relationships
    var recipe: Recipe?
    
    init(
        id: UUID = UUID(),
        stepNumber: Int,
        instruction: String,
        timerDuration: Int? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.timerDuration = timerDuration
        self.imageData = imageData
    }
}

// MARK: - Recipe Category
@Model
final class RecipeCategory {
    var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Recipe.categories)
    var recipes: [Recipe]?
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "fork.knife",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
}

// MARK: - Default Recipe Categories
extension RecipeCategory {
    static var defaultCategories: [RecipeCategory] {
        [
            RecipeCategory(name: "Breakfast", iconName: "sunrise", sortOrder: 0),
            RecipeCategory(name: "Lunch", iconName: "sun.max", sortOrder: 1),
            RecipeCategory(name: "Dinner", iconName: "moon.stars", sortOrder: 2),
            RecipeCategory(name: "Dessert", iconName: "birthday.cake", sortOrder: 3),
            RecipeCategory(name: "Snack", iconName: "leaf", sortOrder: 4),
            RecipeCategory(name: "Appetizer", iconName: "fork.knife", sortOrder: 5),
            RecipeCategory(name: "Soup", iconName: "cup.and.saucer", sortOrder: 6),
            RecipeCategory(name: "Salad", iconName: "leaf.fill", sortOrder: 7),
            RecipeCategory(name: "Main Course", iconName: "flame", sortOrder: 8),
            RecipeCategory(name: "Side Dish", iconName: "square.grid.2x2", sortOrder: 9)
        ]
    }
}

// MARK: - Recipe Tag
@Model
final class RecipeTag {
    var id: UUID
    var name: String
    var colorHex: String
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Recipe.tags)
    var recipes: [Recipe]?
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}

// MARK: - Default Recipe Tags
extension RecipeTag {
    static var defaultTags: [RecipeTag] {
        [
            RecipeTag(name: "Vegetarian", colorHex: "#34C759"),
            RecipeTag(name: "Vegan", colorHex: "#30D158"),
            RecipeTag(name: "Gluten-Free", colorHex: "#FFD60A"),
            RecipeTag(name: "Dairy-Free", colorHex: "#64D2FF"),
            RecipeTag(name: "Quick", colorHex: "#FF9F0A"),
            RecipeTag(name: "Healthy", colorHex: "#32D74B"),
            RecipeTag(name: "Comfort Food", colorHex: "#FF6482"),
            RecipeTag(name: "One-Pot", colorHex: "#BF5AF2"),
            RecipeTag(name: "Slow Cooker", colorHex: "#5E5CE6"),
            RecipeTag(name: "Instant Pot", colorHex: "#FF453A"),
            RecipeTag(name: "Meal Prep", colorHex: "#00C7BE"),
            RecipeTag(name: "Kid-Friendly", colorHex: "#FFD60A")
        ]
    }
}

// MARK: - Recipe Cooking Note
@Model
final class RecipeCookingNote {
    var id: UUID
    var note: String
    var createdDate: Date
    var rating: Double? // 0-5
    var authorName: String?
    
    // Relationships
    var recipe: Recipe?
    
    init(
        id: UUID = UUID(),
        note: String,
        rating: Double? = nil,
        authorName: String? = nil
    ) {
        self.id = id
        self.note = note
        self.createdDate = Date()
        self.rating = rating
        self.authorName = authorName
    }
}

// MARK: - Recipe Collection (Cookbook)
@Model
final class RecipeCollection {
    var id: UUID
    var name: String
    var collectionDescription: String?
    var iconName: String
    var colorHex: String
    var createdDate: Date
    var sortOrder: Int
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Recipe.collections)
    var recipes: [Recipe]?
    
    var recipeCount: Int {
        recipes?.count ?? 0
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        iconName: String = "book",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.collectionDescription = description
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdDate = Date()
        self.sortOrder = sortOrder
    }
}

// MARK: - Sample Data
extension Recipe {
    static var sampleRecipes: [Recipe] {
        let recipe1 = Recipe(
            name: "Classic Spaghetti Carbonara",
            description: "A traditional Italian pasta dish with eggs, cheese, and pancetta",
            prepTime: 10,
            cookTime: 20,
            servings: 4,
            difficulty: .medium,
            rating: 4.5,
            isFavorite: true
        )
        
        let recipe2 = Recipe(
            name: "Chicken Stir Fry",
            description: "Quick and healthy stir fry with vegetables",
            prepTime: 15,
            cookTime: 10,
            servings: 4,
            difficulty: .easy,
            rating: 4.0
        )
        
        let recipe3 = Recipe(
            name: "Chocolate Chip Cookies",
            description: "Soft and chewy homemade cookies",
            prepTime: 15,
            cookTime: 12,
            servings: 24,
            difficulty: .easy,
            rating: 5.0,
            isFavorite: true
        )
        
        return [recipe1, recipe2, recipe3]
    }
}
