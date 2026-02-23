//
//  RecipeDetailView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var recipe: Recipe
    @State private var showEditSheet = false
    @State private var showCookingMode = false
    @State private var showDeleteAlert = false
    @State private var selectedServings: Int
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _selectedServings = State(initialValue: recipe.servings)
    }
    
    private var scaleFactor: Double {
        recipe.scaleServings(to: selectedServings)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recipe Image
                recipeImageSection
                
                // Quick Info Cards
                quickInfoSection
                
                // Description
                if let description = recipe.recipeDescription, !description.isEmpty {
                    descriptionSection(description)
                }
                
                // Tags
                if let tags = recipe.tags, !tags.isEmpty {
                    tagsSection(tags)
                }
                
                // Ingredients
                ingredientsSection
                
                // Instructions
                instructionsSection
                
                // Notes
                if let notes = recipe.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                
                // Cooking Notes/Reviews
                if let cookingNotes = recipe.cookingNotes, !cookingNotes.isEmpty {
                    cookingNotesSection(cookingNotes)
                }
                
                // Stats
                statsSection
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(
                            recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: recipe.isFavorite ? "star.slash" : "star"
                        )
                    }
                    
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Recipe", systemImage: "pencil")
                    }
                    
                    ShareLink(item: recipe.name) {
                        Label("Share Recipe", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            cookingModeButton
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditRecipeView(recipe: recipe)
        }
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe)
        }
        .alert("Delete Recipe?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private var recipeImageSection: some View {
        Group {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var quickInfoSection: some View {
        HStack(spacing: 12) {
            InfoCard(
                title: "Prep",
                value: "\(recipe.prepTime)",
                unit: "min",
                icon: "clock"
            )
            
            InfoCard(
                title: "Cook",
                value: "\(recipe.cookTime)",
                unit: "min",
                icon: "flame"
            )
            
            InfoCard(
                title: "Total",
                value: "\(recipe.totalTime)",
                unit: "min",
                icon: "timer"
            )
            
            InfoCard(
                title: recipe.difficulty.rawValue,
                value: "",
                unit: "",
                icon: recipe.difficulty.icon,
                color: recipe.difficulty.color
            )
        }
    }
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(description)
                .foregroundStyle(.secondary)
        }
    }
    
    private func tagsSection(_ tags: [RecipeTag]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags) { tag in
                        Text(tag.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(tag.color.opacity(0.2))
                            .foregroundStyle(tag.color)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                
                Spacer()
                
                // Servings Adjuster
                HStack(spacing: 8) {
                    Button {
                        if selectedServings > 1 {
                            selectedServings -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(selectedServings) servings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 80)
                    
                    Button {
                        selectedServings += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.accentColor)
                    }
                }
            }
            
            if let ingredients = recipe.ingredients?.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ingredients) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            scaleFactor: scaleFactor
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No ingredients added yet")
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
            
            if let instructions = recipe.instructions?.sorted(by: { $0.stepNumber < $1.stepNumber }) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(instructions) { instruction in
                        InstructionRow(instruction: instruction)
                    }
                }
            } else {
                Text("No instructions added yet")
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personal Notes")
                .font(.headline)
            Text(notes)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func cookingNotesSection(_ notes: [RecipeCookingNote]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cooking Notes")
                .font(.headline)
            
            ForEach(notes.sorted(by: { $0.createdDate > $1.createdDate })) { note in
                VStack(alignment: .leading, spacing: 4) {
                    if let rating = note.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    
                    Text(note.note)
                        .font(.subheadline)
                    
                    HStack {
                        if let author = note.authorName {
                            Text(author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(note.createdDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Times Cooked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(recipe.timesCookedCount)")
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                if let lastCooked = recipe.lastCookedDate {
                    VStack(alignment: .trailing) {
                        Text("Last Cooked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(lastCooked, style: .date)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var cookingModeButton: some View {
        Button {
            showCookingMode = true
            recipe.markAsCooked()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Cooking")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Actions
    
    private func toggleFavorite() {
        withAnimation {
            recipe.isFavorite.toggle()
            recipe.modifiedDate = Date()
        }
    }
    
    private func deleteRecipe() {
        modelContext.delete(recipe)
        dismiss()
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    var color: Color = .accentColor
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            if !value.isEmpty {
                HStack(spacing: 2) {
                    Text(value)
                        .font(.headline)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct IngredientRow: View {
    let ingredient: RecipeIngredient
    let scaleFactor: Double
    @State private var isChecked = false
    
    private var scaledQuantity: Double {
        ingredient.quantity * scaleFactor
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isChecked.toggle()
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isChecked ? .green : .secondary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(String(format: "%.1f", scaledQuantity))
                            .bold()
                        Text(ingredient.unit)
                        Text(ingredient.name)
                        
                        if ingredient.isOptional {
                            Text("(optional)")
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                    .strikethrough(isChecked)
                    .opacity(isChecked ? 0.5 : 1)
                    
                    if let notes = ingredient.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct InstructionRow: View {
    let instruction: RecipeInstruction
    @State private var isCompleted = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(instruction.stepNumber)")
                .font(.title3)
                .bold()
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(isCompleted ? Color.green : Color.accentColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(instruction.instruction)
                    .strikethrough(isCompleted)
                    .opacity(isCompleted ? 0.5 : 1)
                
                if let timerDuration = instruction.timerDuration {
                    HStack {
                        Image(systemName: "timer")
                        Text("\(timerDuration) minutes")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Button {
                    withAnimation {
                        isCompleted.toggle()
                    }
                } label: {
                    Text(isCompleted ? "Mark Incomplete" : "Mark Complete")
                        .font(.caption)
                        .foregroundStyle(.accentColor)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(for: Recipe.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let recipe = Recipe.sampleRecipes[0]
    container.mainContext.insert(recipe)
    
    return NavigationStack {
        RecipeDetailView(recipe: recipe)
    }
    .modelContainer(container)
}
