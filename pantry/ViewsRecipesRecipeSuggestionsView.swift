//
//  RecipeSuggestionsView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct RecipeSuggestionsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var recipes: [Recipe]
    @Query private var pantryItems: [PantryItem]
    
    @State private var showOnlyMakeable = false
    @State private var sortOption: SortOption = .matchPercentage
    
    enum SortOption: String, CaseIterable {
        case matchPercentage = "Match %"
        case difficulty = "Difficulty"
        case totalTime = "Time"
        case rating = "Rating"
    }
    
    private var expiringItems: [PantryItem] {
        pantryItems.filter { $0.isExpiringSoon || $0.isExpired }
    }
    
    private var recipeSuggestions: [(recipe: Recipe, matchPercentage: Double, missing: [RecipeIngredient])] {
        let results = RecipePantryService.makeableRecipes(
            recipes: recipes,
            pantryItems: pantryItems
        )
        
        var filtered = results
        
        if showOnlyMakeable {
            filtered = filtered.filter { $0.matchPercentage == 100.0 }
        }
        
        // Sort based on selected option
        switch sortOption {
        case .matchPercentage:
            filtered.sort { $0.matchPercentage > $1.matchPercentage }
        case .difficulty:
            filtered.sort { $0.recipe.difficulty.rawValue < $1.recipe.difficulty.rawValue }
        case .totalTime:
            filtered.sort { $0.recipe.totalTime < $1.recipe.totalTime }
        case .rating:
            filtered.sort { ($0.recipe.rating ?? 0) > ($1.recipe.rating ?? 0) }
        }
        
        return filtered
    }
    
    private var expiringRecipeSuggestions: [(recipe: Recipe, expiringItems: [PantryItem])] {
        RecipePantryService.suggestRecipesForExpiringItems(
            recipes: recipes,
            expiringItems: expiringItems
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Expiring Items Section
                if !expiringRecipeSuggestions.isEmpty {
                    Section {
                        ForEach(expiringRecipeSuggestions.prefix(5), id: \.recipe.id) { suggestion in
                            NavigationLink(destination: RecipeDetailView(recipe: suggestion.recipe)) {
                                ExpiringRecipeSuggestionRow(
                                    recipe: suggestion.recipe,
                                    expiringItems: suggestion.expiringItems
                                )
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Use Expiring Ingredients")
                        }
                    }
                }
                
                // All Recipes by Match
                Section {
                    if recipeSuggestions.isEmpty {
                        ContentUnavailableView {
                            Label("No Recipes Available", systemImage: "book.closed")
                        } description: {
                            Text("Add some recipes to get started")
                        }
                    } else {
                        ForEach(recipeSuggestions, id: \.recipe.id) { suggestion in
                            NavigationLink(destination: RecipeDetailView(recipe: suggestion.recipe)) {
                                RecipeSuggestionRow(
                                    recipe: suggestion.recipe,
                                    matchPercentage: suggestion.matchPercentage,
                                    missingCount: suggestion.missing.count
                                )
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recipe Matches")
                        Spacer()
                        Text("\(recipeSuggestions.count) recipes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("What Can I Make?")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        
                        Divider()
                        
                        Toggle("Only Show Makeable", isOn: $showOnlyMakeable)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Recipe Suggestion Row
struct RecipeSuggestionRow: View {
    let recipe: Recipe
    let matchPercentage: Double
    let missingCount: Int
    
    var canMake: Bool {
        matchPercentage == 100.0
    }
    
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
                        .font(.title3)
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
                
                // Match indicator
                HStack(spacing: 8) {
                    // Match percentage
                    HStack(spacing: 4) {
                        Image(systemName: canMake ? "checkmark.circle.fill" : "circle.dotted")
                            .foregroundStyle(canMake ? .green : .orange)
                        Text("\(Int(matchPercentage))% match")
                            .foregroundStyle(canMake ? .green : .orange)
                    }
                    .font(.caption)
                    .bold()
                    
                    if missingCount > 0 {
                        Text("• \(missingCount) missing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Time and difficulty
                HStack(spacing: 8) {
                    Label("\(recipe.totalTime) min", systemImage: "clock")
                    Label(recipe.difficulty.rawValue, systemImage: recipe.difficulty.icon)
                        .foregroundStyle(recipe.difficulty.color)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Match percentage circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: matchPercentage / 100)
                    .stroke(canMake ? Color.green : Color.orange, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(matchPercentage))%")
                    .font(.caption2)
                    .bold()
            }
            .frame(width: 44, height: 44)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Expiring Recipe Suggestion Row
struct ExpiringRecipeSuggestionRow: View {
    let recipe: Recipe
    let expiringItems: [PantryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipe.name)
                    .font(.headline)
                
                Spacer()
                
                Label("\(recipe.totalTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Expiring ingredients
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                
                Text("Uses: \(expiringItems.map { $0.name }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: Recipe.self,
        PantryItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // Add sample data
    let recipe1 = Recipe.sampleRecipes[0]
    let recipe2 = Recipe.sampleRecipes[1]
    
    let item1 = PantryItem.sampleItems[0]
    let item2 = PantryItem.sampleItems[1]
    
    container.mainContext.insert(recipe1)
    container.mainContext.insert(recipe2)
    container.mainContext.insert(item1)
    container.mainContext.insert(item2)
    
    return RecipeSuggestionsView()
        .modelContainer(container)
}
