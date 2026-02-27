# CLAUDE.md — AI Assistant Guide for the Pantry App

This file provides context and conventions for AI assistants working on this codebase.

---

## Project Overview

**Pantry** is a native iOS/iPadOS pantry management application built with SwiftUI and SwiftData. It helps users track grocery inventory, manage recipes, generate shopping lists, and track receipts — with no external dependencies (100% native Apple frameworks).

- **Platform:** iOS 17.0+ / iPadOS 17.0+
- **Language:** Swift 5.0+
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData (local on-device; CloudKit infrastructure ready but not active)
- **No third-party packages** — uses only Apple SDKs

---

## Repository Structure

```
pantry/
├── pantry/                          # Main app source
│   ├── pantryApp.swift              # @main entry point, ModelContainer setup
│   ├── ContentView.swift            # Legacy placeholder
│   ├── Models/                      # SwiftData model definitions
│   │   ├── PantryItem.swift         # Core inventory item
│   │   ├── Category.swift           # Categorization with color/icon
│   │   ├── StorageLocation.swift    # Physical storage locations
│   │   ├── Recipe.swift             # Recipe with ingredients & instructions
│   │   ├── RecipeIngredient.swift   # Ingredient linking model
│   │   ├── RecipeInstruction.swift  # Step-by-step instructions
│   │   ├── ShoppingListItem.swift   # Shopping list entries
│   │   ├── Receipt.swift            # Receipt header
│   │   ├── ReceiptItem.swift        # Individual receipt line items
│   │   └── BarcodeMapping.swift     # Barcode-to-product mapping
│   ├── Views/                       # SwiftUI views
│   │   ├── MainTabView.swift        # Root 5-tab navigation
│   │   ├── Pantry/                  # Inventory screens
│   │   │   ├── PantryListView.swift
│   │   │   ├── ItemDetailView.swift
│   │   │   ├── AddEditItemView.swift
│   │   │   └── PantryItemRow.swift
│   │   ├── Recipes/                 # Recipe screens
│   │   │   ├── RecipesListView.swift
│   │   │   ├── RecipeDetailView.swift
│   │   │   ├── AddEditRecipeView.swift
│   │   │   ├── CookingModeView.swift
│   │   │   └── RecipeSuggestionsView.swift
│   │   ├── Shopping/
│   │   │   └── ShoppingListView.swift
│   │   ├── Receipts/
│   │   │   └── ReceiptsListView.swift
│   │   └── Insights/
│   │       └── InsightsView.swift
│   ├── Services/
│   │   └── RecipePantryService.swift  # Business logic (static, pure functions)
│   ├── Assets.xcassets/             # App icons and image assets
│   ├── Info.plist                   # App configuration
│   ├── pantry.entitlements          # iCloud capabilities
│   └── [documentation .md files]    # In-source docs (see below)
├── pantryTests/                     # Unit tests (Swift Testing framework)
├── pantryUITests/                   # UI tests
├── pantry.xcodeproj/                # Xcode project file
└── push_to_github.sh                # Manual Git deployment helper script
```

---

## Architecture

### Pattern: MVVM with SwiftData

This app uses a pragmatic MVVM approach where SwiftData macros (`@Query`, `@Bindable`, `@Model`) replace traditional ViewModels:

- **Models** — `@Model`-annotated SwiftData classes (in `Models/`)
- **Views** — SwiftUI views with `@Query` for reactive data; `@State` for local UI state
- **Service Layer** — `RecipePantryService` contains static business logic functions (no side effects beyond `ModelContext` operations)

### Data Flow

```
User Interaction
      ↓
SwiftUI View (@State change or ModelContext.insert/delete)
      ↓
SwiftData @Query (automatic reactive update)
      ↓
View re-renders
```

### Key Conventions

1. **No `ObservableObject` / `@ObservedObject`** — Use `@Observable` (macro) or SwiftData `@Bindable` instead.
2. **Service methods are static** — `RecipePantryService` functions take `ModelContext` as a parameter; they do not own state.
3. **Computed properties on models** — Logic like `isExpired`, `daysUntilExpiration`, `totalTime` lives on the model itself.
4. **Sample data** — Every major model has a `sampleItems` static property for previews and testing.
5. **Preview containers** — All previews use in-memory `ModelContainer` instances:
   ```swift
   let container = try! ModelContainer(
       for: Recipe.self,
       configurations: ModelConfiguration(isStoredInMemoryOnly: true)
   )
   ```

---

## Data Models

### Core Models

| Model | Key Properties | Relationships |
|---|---|---|
| `PantryItem` | name, quantity, unit, brand, price, expirationDate, barcode, imageData | category, location, receiptItem |
| `Category` | name, colorHex, iconName, isDefault, sortOrder | — |
| `StorageLocation` | name, description, icon | — |
| `ShoppingListItem` | name, quantity, unit, isChecked, priority | pantryItem |
| `Receipt` | store, date, totalAmount | items |
| `ReceiptItem` | name, quantity, price | receipt, pantryItem |
| `BarcodeMapping` | barcode, productName, brand | — |

### Recipe System Models

| Model | Key Properties | Relationships |
|---|---|---|
| `Recipe` | name, prepTime, cookTime, servings, difficulty | ingredients, instructions, categories, tags, cookingNotes, collections |
| `RecipeIngredient` | quantity, unit, isOptional, preparationNotes | recipe, pantryItem |
| `RecipeInstruction` | stepNumber, text, timerMinutes, imageData | recipe |
| `RecipeCategory` | name | recipes |
| `RecipeTag` | name | recipes |
| `RecipeCookingNote` | note, date | recipe |
| `RecipeCollection` | name, description | recipes |

### Delete Rules

- **Cascade:** Recipe → ingredients, instructions, cookingNotes
- **Nullify:** Recipe → tags, categories, collections (they persist independently)

---

## Service Layer: `RecipePantryService`

All methods are static. Located at `pantry/Services/RecipePantryService.swift`.

### Key Methods

```swift
// Recipe–pantry matching
static func makeableRecipes(from pantryItems: [PantryItem], recipes: [Recipe]) -> [(Recipe, Double)]
static func isIngredientAvailable(_ ingredient: RecipeIngredient, in pantryItems: [PantryItem]) -> Bool

// Shopping list generation
static func generateShoppingList(for recipes: [Recipe], from pantryItems: [PantryItem]) -> [ShoppingListItem]

// Ingredient deduction (modifies ModelContext)
static func deductIngredientsFromPantry(_ recipe: Recipe, pantryItems: [PantryItem], context: ModelContext)

// Expiry-based suggestions
static func suggestRecipesForExpiringItems(_ pantryItems: [PantryItem], recipes: [Recipe]) -> [Recipe]

// Unit conversion
static func convertQuantity(_ quantity: Double, from: String, to: String) -> Double?
```

### Ingredient Matching Logic

Matching uses a fuzzy approach (case-insensitive substring matching) in this priority order:
1. Exact name match
2. Pantry item name contains ingredient name
3. Ingredient name contains pantry item name

---

## SwiftData Schema

Defined in `pantryApp.swift`:

```swift
Schema([
    PantryItem.self, Category.self, StorageLocation.self,
    ShoppingListItem.self, Receipt.self, ReceiptItem.self,
    BarcodeMapping.self, Recipe.self, RecipeIngredient.self,
    RecipeInstruction.self, RecipeCategory.self, RecipeTag.self,
    RecipeCookingNote.self, RecipeCollection.self
])
```

When adding a new `@Model` type, you **must** add it to this schema array.

---

## View Conventions

### Navigation Structure

```
MainTabView
├── Tab: Pantry       → PantryListView → ItemDetailView / AddEditItemView
├── Tab: Shopping     → ShoppingListView
├── Tab: Recipes      → RecipesListView → RecipeDetailView → CookingModeView
│                                       → AddEditRecipeView
│                                       → RecipeSuggestionsView
├── Tab: Receipts     → ReceiptsListView (placeholder)
└── Tab: Insights     → InsightsView
```

### Presentation Patterns

- Use `.sheet` for modal forms (add/edit)
- Use `.fullScreenCover` for immersive experiences (CookingModeView)
- Use `.navigationStack` + `NavigationLink` for drill-down navigation

### State Management

```swift
// Query reactive data from SwiftData
@Query private var items: [PantryItem]

// Two-way binding to a SwiftData model
@Bindable var recipe: Recipe

// Local UI state
@State private var showingAddSheet = false
@State private var searchText = ""

// Model context for insert/delete
@Environment(\.modelContext) private var modelContext
```

### Empty State Handling

Every list view must handle the empty state explicitly with a descriptive message and a call-to-action button.

---

## Testing

### Test Structure

- **`pantryTests/`** — Unit tests using Swift Testing (`import Testing`, `@Test` macro)
- **`pantryUITests/`** — UI tests using XCTest

### Running Tests

Build and test via Xcode:
- `Cmd+U` — Run all tests
- Or use `xcodebuild test -scheme pantry -destination 'platform=iOS Simulator,name=iPhone 16'`

> **Note:** There is currently no CI pipeline. Tests are run manually in Xcode.

### Testability

- `RecipePantryService` static methods are straightforward to unit test
- Use in-memory `ModelContainer` for any tests touching SwiftData
- Model computed properties (`isExpired`, `daysUntilExpiration`) are pure and easily unit tested

---

## Development Workflow

### Building

Open `pantry.xcodeproj` in Xcode 15+ and build with `Cmd+B`. No package resolution step needed (no SPM dependencies).

### Adding a New Feature

1. **Model first** — Define or extend `@Model` types in `Models/`
2. **Update schema** — Add new model to the `Schema([...])` in `pantryApp.swift`
3. **Service logic** — Add business logic as static functions in `RecipePantryService` (or a new service file)
4. **Views** — Build SwiftUI views using `@Query` / `@Bindable`
5. **Preview** — Add `#Preview` with an in-memory `ModelContainer`
6. **Tests** — Add unit tests in `pantryTests/`

### Git Workflow

The repo uses feature branches. The main integration branch is `master`.

```bash
# Push changes (current branch: claude/add-claude-documentation-zpZS2)
git add <files>
git commit -m "descriptive commit message"
git push -u origin claude/add-claude-documentation-zpZS2
```

There is also a helper script: `push_to_github.sh` for interactive deployment.

---

## Key Conventions for AI Assistants

### Do

- **Use native Apple APIs only.** Do not introduce third-party Swift packages.
- **Follow the service pattern.** Business logic belongs in `RecipePantryService` (or a new `*Service.swift`), not inside views.
- **Mark computed properties on models**, not views, when logic depends solely on model data.
- **Add `#Preview` blocks** with in-memory containers for every new view.
- **Use `@Query` with sort descriptors** rather than sorting arrays manually in views.
- **Handle empty states** explicitly in every list view.
- **Update the schema array** when adding a new `@Model`.
- **Use SF Symbols** for all icons — no custom image assets for UI icons.
- **Support Dark Mode and Dynamic Type** — use semantic colors and `@ScaledMetric` where appropriate.

### Don't

- Don't use `ObservableObject` / `@StateObject` / `@ObservedObject` — use `@Observable` macro or SwiftData bindings.
- Don't bypass `ModelContext` for persistence — always use `.insert()`, `.delete()`, and `try modelContext.save()`.
- Don't add CloudKit-specific code yet — the infrastructure exists but activation is a future phase.
- Don't hardcode colors — use `Category.colorHex` parsing or semantic SwiftUI colors.
- Don't create view-specific models/structs that duplicate SwiftData models.

---

## Future Roadmap (Phases 2–6)

| Phase | Feature | Status |
|---|---|---|
| 2 | Barcode scanning (AVFoundation) | Infrastructure ready (`BarcodeMapping` model exists) |
| 3 | Receipt OCR processing | Models ready (`Receipt`, `ReceiptItem`) |
| 4 | Push notifications & auto shopping lists | Background mode configured in Info.plist |
| 5 | CloudKit family sharing | Entitlements configured; models all `@Model` |
| 6 | Home screen widgets & App Store polish | Not started |

---

## Documentation Files (in-source)

The `pantry/` directory contains detailed Markdown documentation:

| File | Contents |
|---|---|
| `README.md` | Project overview and quick start |
| `ARCHITECTURE.md` | Deep-dive technical architecture |
| `QUICK_REFERENCE.md` | Model properties and service API cheat sheet |
| `RECIPE_GUIDE.md` | Recipe feature user guide |
| `START_HERE.md` | Onboarding and first-run walkthrough |
| `requirements.md` | Full functional requirements (FR-1 through FR-10) |
| `plan.md` | 6-phase development roadmap |
| `PHASE1_STATUS.md` | Phase 1 implementation tracking |
| `TESTING_CHECKLIST.md` | Manual QA test cases |
| `PROGRESS.md` | Recipe system implementation history |
