# Recipe System Architecture

## Overview

This document provides technical details about the recipe management system implementation in the Pantry Management App.

---

## 📁 File Structure

```
Models/
├── Recipe.swift              # Main recipe model with all relationships
├── (Other pantry models...)

Views/
└── Recipes/
    ├── RecipesListView.swift          # Main recipe list with search/filter
    ├── RecipeDetailView.swift         # Recipe viewing with scaling
    ├── AddEditRecipeView.swift        # Recipe creation/editing form
    ├── CookingModeView.swift          # Full-screen cooking interface
    └── RecipeSuggestionsView.swift    # Smart suggestions based on pantry

Services/
└── RecipePantryService.swift         # Business logic for recipe-pantry integration
```

---

## 🗄️ Data Models

### Core Model: Recipe

```swift
@Model
final class Recipe {
    // Identity & Basic Info
    var id: UUID
    var name: String
    var recipeDescription: String?
    var imageData: Data?
    
    // Timing & Difficulty
    var prepTime: Int          // minutes
    var cookTime: Int          // minutes
    var servings: Int
    var difficulty: RecipeDifficulty
    
    // User Interaction
    var rating: Double?        // 0-5
    var isFavorite: Bool
    var notes: String?
    var sourceURL: String?
    
    // Tracking
    var createdDate: Date
    var modifiedDate: Date
    var lastCookedDate: Date?
    var timesCookedCount: Int
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
}
```

**Key Features:**
- All properties use proper Swift types
- Relationships use `@Relationship` macro with appropriate delete rules
- Computed properties for convenience (`totalTime`, `ingredientCount`, etc.)
- Methods for common operations (`markAsCooked()`, `scaleServings()`)

### Supporting Models

#### RecipeIngredient
- Links ingredients to recipes
- Supports scaling with `scaled(by:)` method
- Optional link to `PantryItem` via UUID for inventory tracking
- Sortable order for presentation

#### RecipeInstruction
- Step-by-step cooking instructions
- Optional timer duration per step
- Optional image data for visual steps
- Sortable by step number

#### RecipeCategory
- Pre-defined and custom categories
- Icon and sort order support
- Many-to-many with recipes

#### RecipeTag
- Flexible tagging system
- Color-coded for visual distinction
- Common tags: dietary restrictions, cooking methods, time constraints

#### RecipeCookingNote
- User reviews and cooking experiences
- Optional rating
- Author tracking for family collaboration
- Date stamped for history

#### RecipeCollection
- User-created recipe organization (cookbooks)
- Color and icon customization
- Recipe count tracking

---

## 🔄 Relationships & Data Flow

### Relationship Types

**Cascade Delete:**
- Recipe → RecipeIngredients
- Recipe → RecipeInstructions
- Recipe → RecipeCookingNotes

*When recipe deleted, these are automatically removed*

**Nullify:**
- Recipe ← → RecipeCategory
- Recipe ← → RecipeTag
- Recipe ← → RecipeCollection

*When recipe deleted, categories/tags/collections remain for other recipes*

### Data Flow Diagram

```
┌─────────────┐
│   Recipe    │
└─────┬───────┘
      │
      ├─[cascade]─→ RecipeIngredient ─[optional]→ PantryItem
      │
      ├─[cascade]─→ RecipeInstruction
      │
      ├─[nullify]─→ RecipeCategory
      │
      ├─[nullify]─→ RecipeTag
      │
      ├─[cascade]─→ RecipeCookingNote
      │
      └─[nullify]─→ RecipeCollection
```

---

## 🎨 View Architecture

### RecipesListView

**Responsibilities:**
- Display all recipes from SwiftData
- Search across name, ingredients, tags
- Filter by multiple criteria
- Swipe actions for quick operations
- Navigation to detail view

**State Management:**
```swift
@Query(sort: \Recipe.modifiedDate, order: .reverse) 
private var recipes: [Recipe]

@State private var searchText = ""
@State private var selectedCategory: RecipeCategory?
@State private var selectedDifficulty: RecipeDifficulty?
@State private var showFavoritesOnly = false
@State private var showMakeableOnly = false
```

**Key Features:**
- Reactive data updates via `@Query`
- Computed property for filtered results
- Empty state handling
- Swipe actions (duplicate, delete, favorite)

### RecipeDetailView

**Responsibilities:**
- Display complete recipe information
- Allow servings adjustment with real-time scaling
- Ingredient checklist functionality
- Step completion tracking
- Launch cooking mode
- Edit/delete operations

**State Management:**
```swift
@Bindable var recipe: Recipe
@State private var selectedServings: Int
@State private var showEditSheet = false
@State private var showCookingMode = false
```

**Key Features:**
- Two-way binding with `@Bindable`
- Dynamic serving scaling via computed property
- Toolbar menu for actions
- Safe area insets for floating button

### AddEditRecipeView

**Responsibilities:**
- Create new recipes
- Edit existing recipes
- Manage ingredients dynamically
- Manage instructions dynamically
- Photo selection

**State Management:**
```swift
var recipe: Recipe? // nil for new, instance for edit

@State private var name = ""
@State private var ingredients: [IngredientInput] = []
@State private var instructions: [InstructionInput] = []
@State private var selectedPhotoItem: PhotosPickerItem?
```

**Key Features:**
- Form-based UI with sections
- PhotosPicker integration
- Dynamic arrays for ingredients/instructions
- Sheet presentations for adding items
- Drag-to-reorder support
- Validation before save

**Pattern: Input Models**
```swift
struct IngredientInput: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var notes: String
    var isOptional: Bool
}
```

*These are temporary structs for form editing, converted to `RecipeIngredient` on save*

### CookingModeView

**Responsibilities:**
- Full-screen cooking experience
- Step navigation
- Timer management
- Progress tracking
- Keep screen awake

**State Management:**
```swift
@Bindable var recipe: Recipe
@State private var currentStepIndex = 0
@State private var completedSteps: Set<Int> = []
@State private var activeTimer: RecipeTimer?
@State private var keepAwake = true
```

**Key Features:**
- `UIApplication.shared.isIdleTimerDisabled` for screen wake
- Custom `RecipeTimer` observable class
- Progress calculation
- Large touch targets
- Completion view

**Custom Timer Class:**
```swift
@Observable
class RecipeTimer {
    var duration: Int
    var remainingTime: Int
    var isPaused = false
    private var timer: Timer?
    
    // Methods: start(), pause()
    // Computed: progress, remainingTimeString
}
```

### RecipeSuggestionsView

**Responsibilities:**
- Show makeable recipes
- Highlight expiring ingredient recipes
- Display match percentages
- Multiple sort options

**State Management:**
```swift
@Query private var recipes: [Recipe]
@Query private var pantryItems: [PantryItem]

@State private var showOnlyMakeable = false
@State private var sortOption: SortOption = .matchPercentage
```

**Key Features:**
- Two `@Query` decorators for different models
- Computed properties calling service methods
- Circular progress indicators
- Color-coded match status

---

## 🔧 Services Layer

### RecipePantryService

**Purpose:** Centralized business logic for recipe-pantry integration

**Key Methods:**

#### 1. Recipe Matching
```swift
static func makeableRecipes(
    recipes: [Recipe],
    pantryItems: [PantryItem]
) -> [(recipe: Recipe, matchPercentage: Double, missingIngredients: [RecipeIngredient])]
```

**Algorithm:**
- Iterate through all recipes
- For each recipe, check each ingredient
- Use fuzzy matching for ingredient names
- Calculate percentage of available ingredients
- Return sorted results

**Matching Strategy:**
1. Exact name match (case-insensitive)
2. Contains match (ingredient name contains pantry item)
3. Reverse contains (pantry item contains ingredient name)
4. Check quantity > 0

#### 2. Inventory Deduction
```swift
static func deductIngredientsFromPantry(
    recipe: Recipe,
    pantryItems: [PantryItem],
    scaleFactor: Double,
    modelContext: ModelContext
) -> [PantryItem]
```

**Process:**
- Find matching pantry items
- Convert units if needed
- Deduct scaled quantities
- Update modification dates
- Return affected items

#### 3. Shopping List Generation
```swift
static func generateShoppingList(
    recipe: Recipe,
    pantryItems: [PantryItem],
    scaleFactor: Double
) -> [ShoppingListItem]
```

**Process:**
- Get missing ingredients
- Create ShoppingListItem for each
- Apply scale factor
- Preserve units and notes

#### 4. Expiring Item Suggestions
```swift
static func suggestRecipesForExpiringItems(
    recipes: [Recipe],
    expiringItems: [PantryItem]
) -> [(recipe: Recipe, expiringIngredientsUsed: [PantryItem])]
```

**Algorithm:**
- Check each recipe's ingredients
- Match against expiring items
- Count expiring ingredients per recipe
- Sort by count (most to least)

#### 5. Unit Conversion
```swift
static func convertQuantity(
    from: String,
    to: String,
    quantity: Double
) -> Double
```

**Supported Conversions:**

**Volume:**
- cup, tbsp, tsp, mL, L, oz (fluid), gallon, quart, pint

**Weight:**
- g, kg, lb, oz (weight)

**Implementation:**
- Lookup tables for base unit conversions
- All volumes convert via mL
- All weights convert via grams

#### 6. Ingredient Substitution
```swift
static let commonSubstitutions: [String: [String]]
```

**Examples:**
- butter → margarine, oil, coconut oil
- milk → almond milk, soy milk, oat milk
- egg → flax egg, chia egg, applesauce

---

## 🎯 Key Design Patterns

### 1. MVVM (Model-View-ViewModel)

**Models:** SwiftData models
**Views:** SwiftUI views
**"ViewModel":** Service layer + computed properties in views

*SwiftUI's `@Query` and `@Bindable` eliminate need for traditional ViewModels*

### 2. Service Layer Pattern

**RecipePantryService:**
- Static methods for stateless operations
- Pure functions (no side effects except ModelContext)
- Reusable across views
- Testable in isolation

### 3. Composition Over Inheritance

**Reusable Components:**
- `RecipeRow` - Recipe list item
- `IngredientRow` - Ingredient with checkbox
- `InstructionRow` - Step with completion
- `InfoCard` - Metadata display card
- `FilterChip` - Toggle filter button

### 4. Unidirectional Data Flow

```
User Action → State Change → View Update
     ↓            ↓              ↑
SwiftUI  →  @State/@Query  →  body
```

### 5. Separation of Concerns

**Views:**
- Presentation only
- State management
- User interaction handling

**Models:**
- Data structure
- Relationships
- Simple computed properties

**Services:**
- Business logic
- Algorithms
- Data transformation

---

## 🔐 Data Persistence & Sync

### SwiftData Configuration

**Schema Registration:**
```swift
let schema = Schema([
    Recipe.self,
    RecipeIngredient.self,
    RecipeInstruction.self,
    RecipeCategory.self,
    RecipeTag.self,
    RecipeCookingNote.self,
    RecipeCollection.self,
    // ... other models
])
```

### CloudKit Integration

**Automatic Sync:**
- SwiftData handles CloudKit sync automatically
- No custom sync code needed
- All `@Model` classes sync by default

**Conflict Resolution:**
- SwiftData uses last-write-wins
- `modifiedDate` tracks changes
- `modifiedBy` field for attribution (optional)

### Relationship Handling

**Cascade Deletes:**
```swift
@Relationship(deleteRule: .cascade)
var ingredients: [RecipeIngredient]?
```

**Nullify:**
```swift
@Relationship(deleteRule: .nullify, inverse: \Recipe.categories)
var recipes: [Recipe]?
```

---

## 🧪 Testing Strategy

### Preview Providers

All views include `#Preview` with:
- In-memory ModelContainer
- Sample data
- Proper model relationships

**Example:**
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

### Unit Testing Opportunities

**Service Layer:**
- `RecipePantryService` methods are static
- Pure functions easy to test
- No dependency injection needed

**Test Cases:**
```swift
// Recipe matching algorithm
func testRecipeMatchingExactMatch()
func testRecipeMatchingFuzzyMatch()
func testRecipeMatchingNoMatch()

// Unit conversion
func testVolumeConversion()
func testWeightConversion()
func testIncompatibleUnits()

// Scaling
func testRecipeScaling()
func testIngredientQuantityCalculation()
```

---

## 📊 Performance Considerations

### Query Optimization

**SwiftData Queries:**
```swift
@Query(sort: \Recipe.modifiedDate, order: .reverse) 
private var recipes: [Recipe]
```

- Sorted at database level
- Lazy loading of relationships
- Reactive updates only when data changes

### Image Handling

**Best Practices:**
- Store compressed image data
- Display thumbnails in lists
- Full resolution in detail view
- Consider lazy loading for large collections

### Search Performance

**Current Implementation:**
- In-memory filtering via computed property
- Acceptable for < 500 recipes

**Future Optimization (if needed):**
- Use `#Predicate` for database-level filtering
- Full-text search via SwiftData predicates

### Cooking Mode Optimization

**Screen Wake:**
- Only active when CookingModeView is visible
- Automatically restored on dismiss

**Timer Efficiency:**
- Single Timer instance
- Invalidated on deinit
- Minimal battery impact

---

## 🚀 Future Enhancements

### Planned Features

1. **Recipe Import**
   - Safari extension or share sheet
   - Parse recipe websites
   - Vision framework for recipe photos

2. **Voice Commands**
   - "Next step"
   - "Start timer"
   - "Show ingredients"

3. **Advanced Meal Planning**
   - Calendar integration
   - Drag-and-drop meal scheduling
   - Auto-generate weekly shopping lists

4. **Social Features**
   - Share recipes publicly
   - Import from community
   - Rate others' recipes

5. **Nutritional Information**
   - Calorie tracking
   - Macro breakdown
   - Dietary goals

### Technical Improvements

1. **Database-level Search**
   ```swift
   @Query(filter: #Predicate<Recipe> { recipe in
       recipe.name.localizedStandardContains(searchText)
   })
   ```

2. **Batch Operations**
   - Import multiple recipes
   - Bulk edit capabilities

3. **Custom Units**
   - User-defined unit conversions
   - Regional unit preferences

4. **Advanced Substitutions**
   - ML-based suggestions
   - Dietary restriction awareness
   - Taste profile matching

---

## 🎓 Learning Resources

### SwiftData
- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- WWDC 2023: Meet SwiftData
- WWDC 2023: Build an app with SwiftData

### SwiftUI
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- WWDC 2023: What's new in SwiftUI

### CloudKit
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- WWDC 2023: Discover Observation in SwiftUI

---

## 📋 Code Style Guidelines

### Naming Conventions
- Models: `Recipe`, `RecipeIngredient` (noun)
- Views: `RecipesListView`, `CookingModeView` (descriptive)
- Services: `RecipePantryService` (noun + Service)

### Organization
- MARK comments for sections
- Group related properties
- Computed properties after stored properties
- Methods after properties

### Documentation
- Doc comments for public APIs
- Inline comments for complex logic
- README files for major features

---

## 🐛 Debugging Tips

### Common Issues

**Recipe not appearing:**
- Check SwiftData query predicates
- Verify model is inserted into context
- Check filter states

**Images not displaying:**
- Verify Data is valid
- Check UIImage initialization
- Confirm PhotosPicker permissions

**Sync not working:**
- Check iCloud settings
- Verify CloudKit container configuration
- Check network connectivity

### Debugging Tools

**SwiftData:**
```swift
// Print all recipes
let recipes = try? modelContext.fetch(FetchDescriptor<Recipe>())
print(recipes)
```

**Preview Crashes:**
- Check model relationships
- Verify in-memory container setup
- Ensure sample data is valid

---

## 📄 License & Credits

**Recipe System Implementation**
- Built with SwiftUI and SwiftData
- Uses Apple's native frameworks exclusively
- No third-party dependencies

**Created:** February 22, 2026
**Version:** 1.0

---

**Questions? Check PROGRESS.md for implementation status and RECIPE_GUIDE.md for user documentation.**
