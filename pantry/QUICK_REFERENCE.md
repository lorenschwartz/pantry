# Quick Reference - Recipe System APIs

## 📋 Models

### Recipe
```swift
let recipe = Recipe(
    name: "Pasta Carbonara",
    description: "Classic Italian pasta",
    prepTime: 10,
    cookTime: 15,
    servings: 4,
    difficulty: .medium
)
```

**Key Properties:**
- `name: String` - Recipe name
- `prepTime: Int` - Minutes
- `cookTime: Int` - Minutes
- `servings: Int` - Number of servings
- `difficulty: RecipeDifficulty` - .easy, .medium, .hard
- `rating: Double?` - 0-5 stars
- `isFavorite: Bool` - Favorite status
- `ingredients: [RecipeIngredient]?` - List of ingredients
- `instructions: [RecipeInstruction]?` - Cooking steps

**Key Methods:**
- `markAsCooked()` - Increment cook count, update date
- `scaleServings(to: Int) -> Double` - Get scaling factor

**Computed:**
- `totalTime: Int` - prep + cook
- `ingredientCount: Int` - Number of ingredients
- `stepCount: Int` - Number of instructions

---

### RecipeIngredient
```swift
let ingredient = RecipeIngredient(
    name: "Spaghetti",
    quantity: 1.0,
    unit: "lb",
    notes: "uncooked",
    isOptional: false,
    sortOrder: 0
)
```

**Key Properties:**
- `name: String` - Ingredient name
- `quantity: Double` - Amount
- `unit: String` - cup, tbsp, oz, etc.
- `notes: String?` - Preparation notes
- `isOptional: Bool` - Optional ingredient flag
- `sortOrder: Int` - Display order

**Key Methods:**
- `scaled(by: Double) -> RecipeIngredient` - Create scaled copy

---

### RecipeInstruction
```swift
let instruction = RecipeInstruction(
    stepNumber: 1,
    instruction: "Boil water in large pot",
    timerDuration: 10
)
```

**Key Properties:**
- `stepNumber: Int` - Step number (1, 2, 3...)
- `instruction: String` - What to do
- `timerDuration: Int?` - Timer in minutes (optional)
- `imageData: Data?` - Optional step image

---

### RecipeCategory
```swift
let category = RecipeCategory(
    name: "Dinner",
    iconName: "moon.stars",
    sortOrder: 2
)
```

**Default Categories:**
- Breakfast, Lunch, Dinner, Dessert, Snack
- Appetizer, Soup, Salad, Main Course, Side Dish

---

### RecipeTag
```swift
let tag = RecipeTag(
    name: "Vegetarian",
    colorHex: "#34C759"
)
```

**Default Tags:**
- Vegetarian, Vegan, Gluten-Free, Dairy-Free
- Quick, Healthy, Comfort Food, One-Pot
- Slow Cooker, Instant Pot, Meal Prep, Kid-Friendly

---

### RecipeCookingNote
```swift
let note = RecipeCookingNote(
    note: "Added extra garlic, turned out great!",
    rating: 5.0,
    authorName: "John"
)
```

---

### RecipeCollection
```swift
let collection = RecipeCollection(
    name: "Family Favorites",
    description: "Our most loved recipes",
    iconName: "heart",
    colorHex: "#FF3B30"
)
```

---

## 🎨 Views

### RecipesListView
```swift
RecipesListView()
```
Main recipe browsing view with search, filters, and actions.

**State:**
- `searchText: String` - Search query
- `selectedCategory: RecipeCategory?` - Category filter
- `selectedDifficulty: RecipeDifficulty?` - Difficulty filter
- `showFavoritesOnly: Bool` - Favorites filter
- `showMakeableOnly: Bool` - Makeable filter

---

### RecipeDetailView
```swift
RecipeDetailView(recipe: myRecipe)
```
Detailed recipe view with scaling and interactions.

**State:**
- `selectedServings: Int` - Adjusted serving size
- `showEditSheet: Bool` - Show edit form
- `showCookingMode: Bool` - Show cooking mode

**Computed:**
- `scaleFactor: Double` - Serving scale multiplier

---

### AddEditRecipeView
```swift
// New recipe
AddEditRecipeView()

// Edit existing
AddEditRecipeView(recipe: myRecipe)
```
Form for creating/editing recipes.

**Key Inputs:**
- All recipe properties as `@State` variables
- `ingredients: [IngredientInput]` - Editable ingredient list
- `instructions: [InstructionInput]` - Editable instruction list

---

### CookingModeView
```swift
CookingModeView(recipe: myRecipe)
```
Full-screen cooking interface.

**State:**
- `currentStepIndex: Int` - Current step (0-based)
- `completedSteps: Set<Int>` - Completed step numbers
- `activeTimer: RecipeTimer?` - Active timer instance

**Key Feature:** Screen stays awake automatically

---

### RecipeSuggestionsView
```swift
RecipeSuggestionsView()
```
Smart suggestions based on pantry.

**Queries:**
- `recipes: [Recipe]` - All recipes
- `pantryItems: [PantryItem]` - All pantry items

**Computed:**
- `recipeSuggestions` - Recipes with match percentages
- `expiringRecipeSuggestions` - Recipes using expiring items

---

## 🔧 Services

### RecipePantryService

**Check Recipe Makeable:**
```swift
let result = RecipePantryService.checkRecipeMakeable(
    recipe: myRecipe,
    pantryItems: allPantryItems
)
// Returns: (matchPercentage, missingIngredients, availableIngredients)

print("Can make \(result.matchPercentage)% of recipe")
print("Missing: \(result.missingIngredients.count) ingredients")
```

**Get All Makeable Recipes:**
```swift
let suggestions = RecipePantryService.makeableRecipes(
    recipes: allRecipes,
    pantryItems: allPantryItems
)

for suggestion in suggestions {
    print("\(suggestion.recipe.name): \(suggestion.matchPercentage)%")
}
```

**Deduct From Pantry:**
```swift
let updatedItems = RecipePantryService.deductIngredientsFromPantry(
    recipe: myRecipe,
    pantryItems: allPantryItems,
    scaleFactor: 1.5,  // 1.5x the recipe
    modelContext: context
)
// Automatically updates quantities
```

**Generate Shopping List:**
```swift
let shoppingItems = RecipePantryService.generateShoppingList(
    recipe: myRecipe,
    pantryItems: allPantryItems,
    scaleFactor: 1.0
)
// Returns [ShoppingListItem] for missing ingredients
```

**Suggest for Expiring:**
```swift
let expiringItems = pantryItems.filter { $0.isExpiringSoon }
let suggestions = RecipePantryService.suggestRecipesForExpiringItems(
    recipes: allRecipes,
    expiringItems: expiringItems
)

for suggestion in suggestions {
    print("\(suggestion.recipe.name) uses:")
    for item in suggestion.expiringIngredientsUsed {
        print("  - \(item.name)")
    }
}
```

**Convert Units:**
```swift
let converted = RecipePantryService.convertQuantity(
    from: "cup",
    to: "mL",
    quantity: 2.0
)
// Returns 480.0 (2 cups = 480 mL)
```

**Find Substitutions:**
```swift
let substitutes = RecipePantryService.findSubstitutions(
    for: eggIngredient,
    in: allPantryItems
)
// Returns pantry items that can substitute for eggs
```

---

## 🎯 Common Patterns

### Creating a Complete Recipe

```swift
// 1. Create recipe
let recipe = Recipe(
    name: "Spaghetti Carbonara",
    prepTime: 10,
    cookTime: 15,
    servings: 4,
    difficulty: .medium
)
modelContext.insert(recipe)

// 2. Add ingredients
let pasta = RecipeIngredient(
    name: "Spaghetti",
    quantity: 1.0,
    unit: "lb",
    sortOrder: 0
)
let eggs = RecipeIngredient(
    name: "Eggs",
    quantity: 4.0,
    unit: "count",
    sortOrder: 1
)

modelContext.insert(pasta)
modelContext.insert(eggs)
recipe.ingredients = [pasta, eggs]

// 3. Add instructions
let step1 = RecipeInstruction(
    stepNumber: 1,
    instruction: "Boil water",
    timerDuration: 10
)
let step2 = RecipeInstruction(
    stepNumber: 2,
    instruction: "Cook pasta"
)

modelContext.insert(step1)
modelContext.insert(step2)
recipe.instructions = [step1, step2]
```

---

### Querying Recipes

```swift
// All recipes (sorted by modified date)
@Query(sort: \Recipe.modifiedDate, order: .reverse)
private var recipes: [Recipe]

// Favorite recipes only
@Query(filter: #Predicate<Recipe> { $0.isFavorite })
private var favorites: [Recipe]

// Recipes by difficulty
@Query(filter: #Predicate<Recipe> { recipe in
    recipe.difficulty == .easy
})
private var easyRecipes: [Recipe]
```

---

### Scaling a Recipe

```swift
// In view
let originalServings = recipe.servings
let desiredServings = 8

// Get scale factor
let factor = recipe.scaleServings(to: desiredServings)

// Scale ingredients
for ingredient in recipe.ingredients ?? [] {
    let scaledQty = ingredient.quantity * factor
    print("\(scaledQty) \(ingredient.unit) \(ingredient.name)")
}
```

---

### Check If Recipe Can Be Made

```swift
let result = RecipePantryService.checkRecipeMakeable(
    recipe: recipe,
    pantryItems: pantryItems
)

if result.matchPercentage == 100.0 {
    print("✅ Can make this recipe!")
} else {
    print("⚠️ Missing \(result.missingIngredients.count) ingredients:")
    for ingredient in result.missingIngredients {
        print("  - \(ingredient.name)")
    }
}
```

---

### Working with Timers in Cooking Mode

```swift
// Create timer
let timer = RecipeTimer(duration: 600) // 10 minutes in seconds

// Start
timer.start()

// Access properties
print(timer.remainingTimeString) // "10:00"
print(timer.progress)             // 0.0 to 1.0

// Pause/Resume
timer.pause()  // Toggle

// Timer auto-updates every second
```

---

## 🔍 SwiftData Patterns

### Insert with Relationships

```swift
let recipe = Recipe(name: "Test")
let ingredient = RecipeIngredient(name: "Sugar", quantity: 1, unit: "cup")

modelContext.insert(recipe)
modelContext.insert(ingredient)

recipe.ingredients?.append(ingredient)
// Relationship automatically maintained
```

---

### Delete with Cascade

```swift
// Deleting recipe automatically deletes:
// - All RecipeIngredients
// - All RecipeInstructions
// - All RecipeCookingNotes
modelContext.delete(recipe)
```

---

### Update Properties

```swift
recipe.name = "New Name"
recipe.modifiedDate = Date()
// SwiftData auto-saves
```

---

## 🎨 UI Components

### Recipe Row
```swift
RecipeRow(recipe: myRecipe)
```
Reusable recipe list item.

---

### Ingredient Row
```swift
IngredientRow(
    ingredient: myIngredient,
    scaleFactor: 1.5
)
```
Checkable ingredient with scaled quantity.

---

### Instruction Row
```swift
InstructionRow(instruction: myInstruction)
```
Step with completion toggle.

---

### Info Card
```swift
InfoCard(
    title: "Prep",
    value: "10",
    unit: "min",
    icon: "clock"
)
```
Metadata display card.

---

### Filter Chip
```swift
FilterChip(
    title: "Favorites",
    isSelected: true,
    systemImage: "star.fill"
) {
    // Toggle action
}
```

---

## 💾 Sample Data

### Get Sample Recipes
```swift
let samples = Recipe.sampleRecipes
// Returns 3 pre-made recipes for testing
```

### Default Categories
```swift
let categories = RecipeCategory.defaultCategories
// Returns 10 default categories
```

### Default Tags
```swift
let tags = RecipeTag.defaultTags
// Returns 12 common tags
```

---

## 🐛 Common Debugging

### Print All Recipes
```swift
let descriptor = FetchDescriptor<Recipe>()
let recipes = try? modelContext.fetch(descriptor)
print(recipes)
```

### Check Relationships
```swift
print("Ingredients: \(recipe.ingredients?.count ?? 0)")
print("Instructions: \(recipe.instructions?.count ?? 0)")
```

### Verify Match Algorithm
```swift
let result = RecipePantryService.checkRecipeMakeable(
    recipe: recipe,
    pantryItems: pantryItems
)
print("Match: \(result.matchPercentage)%")
print("Available: \(result.availableIngredients.map { $0.name })")
print("Missing: \(result.missingIngredients.map { $0.name })")
```

---

## 📱 Environment Access

### In Views
```swift
@Environment(\.modelContext) private var modelContext
@Environment(\.dismiss) private var dismiss

// Use context
modelContext.insert(recipe)
modelContext.delete(recipe)

// Dismiss sheet/modal
dismiss()
```

---

## 🎯 Preview Patterns

### Basic Preview
```swift
#Preview {
    RecipesListView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
```

### Preview with Sample Data
```swift
#Preview {
    let container = try! ModelContainer(
        for: Recipe.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let recipe = Recipe.sampleRecipes[0]
    container.mainContext.insert(recipe)
    
    return RecipeDetailView(recipe: recipe)
        .modelContainer(container)
}
```

---

**Quick Reference v1.0**
**Last Updated:** February 22, 2026
