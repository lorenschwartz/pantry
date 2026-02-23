//
//  RecipesListView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct RecipesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.modifiedDate, order: .reverse) private var recipes: [Recipe]
    
    @State private var searchText = ""
    @State private var selectedCategory: RecipeCategory?
    @State private var selectedDifficulty: RecipeDifficulty?
    @State private var showFavoritesOnly = false
    @State private var showMakeableOnly = false
    @State private var showAddRecipe = false
    
    var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            // Search filter
            if !searchText.isEmpty {
                let nameMatch = recipe.name.localizedCaseInsensitiveContains(searchText)
                let ingredientsMatch = recipe.ingredients?.contains { ingredient in
                    ingredient.name.localizedCaseInsensitiveContains(searchText)
                } ?? false
                let tagsMatch = recipe.tags?.contains { tag in
                    tag.name.localizedCaseInsensitiveContains(searchText)
                } ?? false
                
                guard nameMatch || ingredientsMatch || tagsMatch else { return false }
            }
            
            // Category filter
            if let selectedCategory = selectedCategory {
                guard recipe.categories?.contains(where: { $0.id == selectedCategory.id }) ?? false else { return false }
            }
            
            // Difficulty filter
            if let selectedDifficulty = selectedDifficulty {
                guard recipe.difficulty == selectedDifficulty else { return false }
            }
            
            // Favorites filter
            if showFavoritesOnly {
                guard recipe.isFavorite else { return false }
            }
            
            return true
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    emptyStateView
                } else {
                    recipeListContent
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        filterMenu
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddRecipe) {
                AddEditRecipeView()
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Recipes Yet", systemImage: "book")
        } description: {
            Text("Add your first recipe to get started")
        } actions: {
            Button("Add Recipe") {
                showAddRecipe = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var recipeListContent: some View {
        List {
            // Quick Filters Section
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "Favorites",
                            isSelected: showFavoritesOnly,
                            systemImage: "star.fill"
                        ) {
                            showFavoritesOnly.toggle()
                        }
                        
                        FilterChip(
                            title: "Can Make",
                            isSelected: showMakeableOnly,
                            systemImage: "checkmark.circle.fill"
                        ) {
                            showMakeableOnly.toggle()
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // Recipes List
            Section {
                if filteredRecipes.isEmpty {
                    ContentUnavailableView {
                        Label("No Recipes Found", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try adjusting your search or filters")
                    }
                } else {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeRow(recipe: recipe)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteRecipe(recipe)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                toggleFavorite(recipe)
                            } label: {
                                Label("Favorite", systemImage: recipe.isFavorite ? "star.slash" : "star")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                // Duplicate recipe
                                duplicateRecipe(recipe)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                if !filteredRecipes.isEmpty {
                    Text("\(filteredRecipes.count) \(filteredRecipes.count == 1 ? "Recipe" : "Recipes")")
                }
            }
        }
    }
    
    private var filterMenu: some View {
        Group {
            Menu("Difficulty") {
                Button(selectedDifficulty == nil ? "✓ All" : "All") {
                    selectedDifficulty = nil
                }
                Divider()
                ForEach([RecipeDifficulty.easy, .medium, .hard], id: \.self) { difficulty in
                    Button(selectedDifficulty == difficulty ? "✓ \(difficulty.rawValue)" : difficulty.rawValue) {
                        selectedDifficulty = difficulty == selectedDifficulty ? nil : difficulty
                    }
                }
            }
            
            Button(showFavoritesOnly ? "Show All Recipes" : "Show Favorites Only") {
                showFavoritesOnly.toggle()
            }
            
            Divider()
            
            Button("Clear Filters") {
                selectedCategory = nil
                selectedDifficulty = nil
                showFavoritesOnly = false
                showMakeableOnly = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleFavorite(_ recipe: Recipe) {
        withAnimation {
            recipe.isFavorite.toggle()
            recipe.modifiedDate = Date()
        }
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        withAnimation {
            modelContext.delete(recipe)
        }
    }
    
    private func duplicateRecipe(_ recipe: Recipe) {
        let newRecipe = Recipe(
            name: "\(recipe.name) (Copy)",
            description: recipe.recipeDescription,
            imageData: recipe.imageData,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            servings: recipe.servings,
            difficulty: recipe.difficulty,
            notes: recipe.notes,
            sourceURL: recipe.sourceURL
        )
        
        modelContext.insert(newRecipe)
        
        // Duplicate ingredients
        if let ingredients = recipe.ingredients {
            for ingredient in ingredients {
                let newIngredient = RecipeIngredient(
                    name: ingredient.name,
                    quantity: ingredient.quantity,
                    unit: ingredient.unit,
                    notes: ingredient.notes,
                    isOptional: ingredient.isOptional,
                    sortOrder: ingredient.sortOrder
                )
                newRecipe.ingredients?.append(newIngredient)
                modelContext.insert(newIngredient)
            }
        }
        
        // Duplicate instructions
        if let instructions = recipe.instructions {
            for instruction in instructions {
                let newInstruction = RecipeInstruction(
                    stepNumber: instruction.stepNumber,
                    instruction: instruction.instruction,
                    timerDuration: instruction.timerDuration
                )
                newRecipe.instructions?.append(newInstruction)
                modelContext.insert(newInstruction)
            }
        }
    }
}

// MARK: - Recipe Row
struct RecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe Image
            Group {
                if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name)
                        .font(.headline)
                    
                    if recipe.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                
                // Tags and metadata
                HStack(spacing: 8) {
                    Label("\(recipe.totalTime) min", systemImage: "clock")
                    Label("\(recipe.servings)", systemImage: "person.2")
                    
                    if let rating = recipe.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                            Text(String(format: "%.1f", rating))
                        }
                        .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                // Difficulty badge
                HStack(spacing: 4) {
                    Image(systemName: recipe.difficulty.icon)
                    Text(recipe.difficulty.rawValue)
                }
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(recipe.difficulty.color.opacity(0.2))
                .foregroundStyle(recipe.difficulty.color)
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview
#Preview {
    RecipesListView()
        .modelContainer(for: [Recipe.self], inMemory: true)
}
