# Recipe System - Testing Checklist

Use this checklist to verify all recipe features are working correctly.

---

## ✅ Build & Run

- [ ] Project builds without errors
- [ ] No SwiftData schema warnings
- [ ] App launches successfully
- [ ] All tabs visible in TabBar
- [ ] Recipes tab accessible

---

## ✅ Recipe Creation

### Basic Recipe Creation
- [ ] Tap + button opens Add Recipe sheet
- [ ] Can enter recipe name (required)
- [ ] Can enter description
- [ ] Can select photo from library
- [ ] Can set prep time (stepper works)
- [ ] Can set cook time (stepper works)
- [ ] Can set servings (stepper works)
- [ ] Can select difficulty (picker works)
- [ ] Can toggle favorite
- [ ] Save button disabled when name empty
- [ ] Save button enabled when name filled
- [ ] Cancel dismisses sheet without saving

### Ingredient Management
- [ ] "Add Ingredient" button opens sheet
- [ ] Can enter ingredient name
- [ ] Can enter quantity (number input)
- [ ] Can select unit from picker
- [ ] Can add preparation notes
- [ ] Can mark ingredient as optional
- [ ] Ingredient appears in list after adding
- [ ] Can add multiple ingredients
- [ ] Can drag to reorder ingredients (when in edit mode)
- [ ] Can swipe to delete ingredient
- [ ] Common units available (cup, tbsp, tsp, oz, lb, g, etc.)

### Instruction Management
- [ ] "Add Step" button opens sheet
- [ ] Can enter instruction text (multi-line)
- [ ] Can toggle "Add Timer"
- [ ] Can set timer duration (stepper)
- [ ] Instruction appears in list after adding
- [ ] Steps auto-numbered
- [ ] Can add multiple instructions
- [ ] Can drag to reorder instructions (when in edit mode)
- [ ] Can swipe to delete instruction

### Saving
- [ ] Tap Save creates new recipe
- [ ] Sheet dismisses after save
- [ ] Recipe appears in list view
- [ ] All entered data persists
- [ ] Photo displays correctly
- [ ] Ingredients saved in order
- [ ] Instructions saved in order

---

## ✅ Recipe List View

### Display
- [ ] Recipes appear in list
- [ ] Recipe images display (or placeholder icon)
- [ ] Recipe name visible
- [ ] Favorite star shows for favorited recipes
- [ ] Total time displays
- [ ] Servings count displays
- [ ] Rating displays (if set)
- [ ] Difficulty badge shows with correct color
- [ ] Empty state appears when no recipes

### Search
- [ ] Search bar visible
- [ ] Can type in search bar
- [ ] Results filter as you type
- [ ] Search finds recipes by name
- [ ] Search finds recipes by ingredient
- [ ] Search finds recipes by tag
- [ ] Clear search shows all recipes

### Filters
- [ ] Filter menu button (line.3.horizontal.decrease.circle) visible
- [ ] Favorites filter chip works (toggle on/off)
- [ ] "Can Make" filter chip works
- [ ] Difficulty filter in menu works
- [ ] "Show Favorites Only" menu item works
- [ ] "Clear Filters" resets all filters
- [ ] Filtered count updates correctly

### Actions
- [ ] Tap recipe opens detail view
- [ ] Swipe left reveals Duplicate button (blue)
- [ ] Duplicate creates copy with "(Copy)" suffix
- [ ] Swipe right reveals Delete (red) and Favorite (yellow)
- [ ] Delete removes recipe from list
- [ ] Favorite toggles star on/off

---

## ✅ Recipe Detail View

### Display
- [ ] Recipe name in navigation title
- [ ] Recipe image displays (if available)
- [ ] Info cards show: Prep, Cook, Total time, Difficulty
- [ ] Description displays (if set)
- [ ] Tags display in horizontal scroll (if any)
- [ ] Ingredients section displays
- [ ] Instructions section displays
- [ ] Personal notes display (if set)
- [ ] Statistics section displays
- [ ] Times cooked count shows
- [ ] Last cooked date shows (if cooked)

### Servings Scaling
- [ ] Servings count displays
- [ ] Minus button decreases servings
- [ ] Plus button increases servings
- [ ] Ingredient quantities update when servings changed
- [ ] Quantities display correctly scaled
- [ ] Can't go below 1 serving

### Ingredients Interaction
- [ ] Can tap ingredient to check/uncheck
- [ ] Checkmark appears when checked
- [ ] Strikethrough applies when checked
- [ ] Opacity changes when checked
- [ ] Optional ingredients show "(optional)"
- [ ] Preparation notes display

### Instructions Interaction
- [ ] Steps numbered correctly
- [ ] "Mark Complete" button works
- [ ] Step strikes through when completed
- [ ] Step number turns green when completed
- [ ] Timer indicator shows for timed steps
- [ ] Can toggle between complete/incomplete

### Toolbar Menu (•••)
- [ ] Menu button visible
- [ ] "Add to Favorites" / "Remove from Favorites" works
- [ ] "Edit Recipe" opens edit sheet
- [ ] "Share Recipe" opens iOS share sheet
- [ ] "Delete Recipe" shows confirmation alert
- [ ] Delete actually removes recipe
- [ ] Delete returns to list view

### Start Cooking Button
- [ ] Button visible at bottom of screen
- [ ] Button has glass/material background
- [ ] Tapping opens cooking mode (full screen)
- [ ] Times cooked increments after starting
- [ ] Last cooked date updates

---

## ✅ Recipe Editing

### Opening Edit Mode
- [ ] Edit button in detail view opens sheet
- [ ] Sheet shows all current data
- [ ] Recipe name pre-filled
- [ ] Description pre-filled
- [ ] Photo displays if exists
- [ ] All timing values pre-filled
- [ ] Difficulty pre-selected
- [ ] Ingredients list populated
- [ ] Instructions list populated

### Editing
- [ ] Can change recipe name
- [ ] Can change all fields
- [ ] Can replace photo
- [ ] Can add more ingredients
- [ ] Can delete existing ingredients
- [ ] Can reorder ingredients
- [ ] Can add more instructions
- [ ] Can delete existing instructions
- [ ] Can reorder instructions

### Saving Edits
- [ ] Save updates recipe
- [ ] Changes appear immediately in detail view
- [ ] Changes persist after app restart
- [ ] Modified date updates

---

## ✅ Cooking Mode

### Opening
- [ ] Full screen presentation
- [ ] Navigation bar with recipe name
- [ ] Done button visible
- [ ] Done button dismisses cooking mode

### Display
- [ ] Progress bar at top shows progress
- [ ] Step counter shows "Step X of Y"
- [ ] Current step number displays (large circle)
- [ ] Step number is huge and readable
- [ ] Instruction text is large and readable
- [ ] Text is centered and easy to read

### Navigation
- [ ] Previous button visible (disabled on step 1)
- [ ] Next button visible
- [ ] Previous button goes back a step
- [ ] Next button advances step
- [ ] Progress bar updates when navigating
- [ ] Step counter updates

### Step Completion
- [ ] "Mark as Complete" button visible
- [ ] Button text changes to "Completed" when marked
- [ ] Step number turns green when completed
- [ ] Button color changes to green
- [ ] Can unmark by tapping again

### Timer Functionality
- [ ] Timer button visible on timed steps
- [ ] Timer button shows duration (e.g., "10 minute timer")
- [ ] Tapping timer starts countdown
- [ ] Timer appears at bottom of screen
- [ ] Timer shows MM:SS format
- [ ] Timer counts down
- [ ] Can pause/resume timer
- [ ] Can dismiss timer with X button
- [ ] Timer progress bar updates

### All Steps Overview
- [ ] "All Steps" section visible
- [ ] Shows all steps in list
- [ ] Current step highlighted
- [ ] Completed steps show green checkmark
- [ ] Can tap step to jump to it
- [ ] Timer icon shows on timed steps

### Screen Wake
- [ ] Screen stays awake during cooking
- [ ] Screen doesn't dim/sleep
- [ ] Screen lock restored after exiting

### Completion
- [ ] Completion view shows after last step + Next
- [ ] Green checkmark shows
- [ ] "Recipe Complete!" message
- [ ] "Finish Cooking" button dismisses
- [ ] "Start Over" resets to step 1

---

## ✅ Recipe Suggestions

### Display
- [ ] Navigation title "What Can I Make?"
- [ ] Two main sections visible
- [ ] "Use Expiring Ingredients" section (if applicable)
- [ ] "Recipe Matches" section

### Expiring Ingredients Section
- [ ] Shows recipes using items expiring soon
- [ ] Orange warning icon visible
- [ ] Lists which expiring items are used
- [ ] Only appears if there are expiring items
- [ ] Tapping recipe opens detail view

### Recipe Matches Section
- [ ] All recipes listed
- [ ] Match percentage shows (0-100%)
- [ ] Circular progress indicator displays
- [ ] Green checkmark for 100% match
- [ ] Orange circle for partial matches
- [ ] Missing ingredient count shows
- [ ] Recipe info displays (time, difficulty)
- [ ] Recipe count in header

### Sorting & Filtering
- [ ] Filter menu button visible
- [ ] "Sort By" picker works
- [ ] Sort by Match % works (default)
- [ ] Sort by Difficulty works
- [ ] Sort by Time works
- [ ] Sort by Rating works
- [ ] "Only Show Makeable" toggle works
- [ ] Recipe list updates when sorted/filtered

### Pantry Integration
- [ ] Match percentage accurate
- [ ] Recipes with all ingredients show 100%
- [ ] Missing count accurate
- [ ] Expiring items properly detected

---

## ✅ Data Persistence

### After App Restart
- [ ] All recipes still present
- [ ] All recipe data intact
- [ ] Photos persist
- [ ] Ingredients persist in order
- [ ] Instructions persist in order
- [ ] Favorites status persists
- [ ] Cooking statistics persist
- [ ] Ratings persist

### SwiftData
- [ ] No data loss on app termination
- [ ] No data corruption
- [ ] Relationships intact
- [ ] Delete operations clean

---

## ✅ Integration Features

### Pantry Matching
- [ ] Service correctly identifies matching ingredients
- [ ] Fuzzy matching works (variations in names)
- [ ] Match percentages calculated correctly
- [ ] Missing ingredients identified

### Unit Conversion
- [ ] Volume conversions work
- [ ] Weight conversions work
- [ ] Same-unit returns same quantity
- [ ] Invalid conversions return original

### Ingredient Substitution
- [ ] Common substitutions defined
- [ ] Can find substitutes in pantry (via service)

---

## ✅ UI/UX Polish

### Design
- [ ] Consistent spacing throughout
- [ ] Proper use of SF Symbols
- [ ] Color scheme consistent
- [ ] Dark mode works correctly
- [ ] Dynamic Type scales properly

### Animations
- [ ] Swipe actions smooth
- [ ] Sheet presentations smooth
- [ ] Navigation transitions smooth
- [ ] Filter chip toggles have animation
- [ ] Checkbox animations in ingredients
- [ ] Step completion animations

### Accessibility
- [ ] VoiceOver labels present (test if possible)
- [ ] Dynamic Type scaling works
- [ ] Tap targets are large enough
- [ ] Color contrast sufficient

### iPad
- [ ] Layout adapts to iPad screen
- [ ] Navigation split view works
- [ ] Landscape mode works
- [ ] Cooking mode works in landscape

---

## ✅ Edge Cases

### Empty States
- [ ] Empty recipe list shows appropriate message
- [ ] No ingredients shows message
- [ ] No instructions shows message
- [ ] No search results shows message

### Validation
- [ ] Can't save recipe without name
- [ ] Can't add ingredient without name
- [ ] Can't add instruction without text
- [ ] Servings can't go below 1

### Deletion
- [ ] Delete confirmation alerts work
- [ ] Cascade deletes work (ingredients, instructions deleted with recipe)
- [ ] Nullify works (categories, tags, collections remain)

---

## ✅ Performance

### List Scrolling
- [ ] Recipe list scrolls smoothly
- [ ] Images load without lag
- [ ] Search filtering is responsive

### Large Data Sets
- [ ] Test with 50+ recipes (if possible)
- [ ] No slowdown with many recipes
- [ ] Search still fast

### Memory
- [ ] No obvious memory leaks
- [ ] Images release properly
- [ ] Cooking mode timer cleans up

---

## 🐛 Known Issues to Watch For

Issues to check for and report:

- [ ] Photos not loading (permissions?)
- [ ] SwiftData context errors
- [ ] Cooking mode screen sleeping
- [ ] Timer not counting down
- [ ] Ingredient scaling incorrect
- [ ] Search not finding recipes
- [ ] Sync issues (if testing with multiple devices)
- [ ] Crash on delete
- [ ] Missing relationships (ingredients/instructions disappearing)

---

## 📝 Testing Notes

**Date Tested:** __________

**Device:** __________

**iOS Version:** __________

**Issues Found:**
```
1. 
2. 
3. 
```

**Features Working Well:**
```
1. 
2. 
3. 
```

**Suggestions:**
```
1. 
2. 
3. 
```

---

## ✅ Final Verification

- [ ] All critical features working
- [ ] No crashes during normal use
- [ ] Data persists correctly
- [ ] UI is responsive and smooth
- [ ] Ready for next development phase

---

**Tester:** __________
**Date:** __________
**Status:** ⬜ Pass / ⬜ Fail / ⬜ Needs Work
