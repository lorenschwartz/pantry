//
//  AddEditRecipeView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var recipe: Recipe?
    
    @State private var name = ""
    @State private var recipeDescription = ""
    @State private var prepTime = 0
    @State private var cookTime = 0
    @State private var servings = 4
    @State private var difficulty = RecipeDifficulty.medium
    @State private var isFavorite = false
    @State private var notes = ""
    @State private var sourceURL = ""
    
    @State private var ingredients: [IngredientInput] = []
    @State private var instructions: [InstructionInput] = []
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    @State private var showingAddIngredient = false
    @State private var showingAddInstruction = false
    
    var isEditing: Bool {
        recipe != nil
    }
    
    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        
        if let recipe = recipe {
            _name = State(initialValue: recipe.name)
            _recipeDescription = State(initialValue: recipe.recipeDescription ?? "")
            _prepTime = State(initialValue: recipe.prepTime)
            _cookTime = State(initialValue: recipe.cookTime)
            _servings = State(initialValue: recipe.servings)
            _difficulty = State(initialValue: recipe.difficulty)
            _isFavorite = State(initialValue: recipe.isFavorite)
            _notes = State(initialValue: recipe.notes ?? "")
            _sourceURL = State(initialValue: recipe.sourceURL ?? "")
            _selectedImageData = State(initialValue: recipe.imageData)
            
            // Convert existing ingredients
            if let existingIngredients = recipe.ingredients?.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                _ingredients = State(initialValue: existingIngredients.map { ing in
                    IngredientInput(
                        name: ing.name,
                        quantity: ing.quantity,
                        unit: ing.unit,
                        notes: ing.notes ?? "",
                        isOptional: ing.isOptional
                    )
                })
            }
            
            // Convert existing instructions
            if let existingInstructions = recipe.instructions?.sorted(by: { $0.stepNumber < $1.stepNumber }) {
                _instructions = State(initialValue: existingInstructions.map { inst in
                    InstructionInput(
                        instruction: inst.instruction,
                        timerDuration: inst.timerDuration
                    )
                })
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Recipe Name", text: $name)
                    
                    TextField("Description", text: $recipeDescription, axis: .vertical)
                        .lineLimit(3...5)
                    
                    // Photo Picker
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Recipe Photo")
                                    .font(.headline)
                                Text("Tap to select")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }
                
                // Timing Section
                Section("Timing & Servings") {
                    Stepper("Prep Time: \(prepTime) min", value: $prepTime, in: 0...300, step: 5)
                    Stepper("Cook Time: \(cookTime) min", value: $cookTime, in: 0...480, step: 5)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach([RecipeDifficulty.easy, .medium, .hard], id: \.self) { diff in
                            HStack {
                                Image(systemName: diff.icon)
                                Text(diff.rawValue)
                            }
                            .tag(diff)
                        }
                    }
                }
                
                // Ingredients Section
                Section {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(ingredients[index].name)
                                    .font(.headline)
                                Text("\(String(format: "%.1f", ingredients[index].quantity)) \(ingredients[index].unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                ingredients.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .onMove { from, to in
                        ingredients.move(fromOffsets: from, toOffset: to)
                    }
                    
                    Button {
                        showingAddIngredient = true
                    } label: {
                        Label("Add Ingredient", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    if !ingredients.isEmpty {
                        Text("Drag to reorder")
                            .font(.caption)
                    }
                }
                
                // Instructions Section
                Section {
                    ForEach(instructions.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading) {
                                Text(instructions[index].instruction)
                                
                                if let timer = instructions[index].timerDuration {
                                    HStack {
                                        Image(systemName: "timer")
                                        Text("\(timer) min")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                instructions.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .onMove { from, to in
                        instructions.move(fromOffsets: from, toOffset: to)
                    }
                    
                    Button {
                        showingAddInstruction = true
                    } label: {
                        Label("Add Step", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Instructions")
                } footer: {
                    if !instructions.isEmpty {
                        Text("Drag to reorder")
                            .font(.caption)
                    }
                }
                
                // Additional Info Section
                Section("Additional Information") {
                    TextField("Source URL", text: $sourceURL)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    
                    TextField("Personal Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(name.isEmpty)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientSheet { ingredient in
                    ingredients.append(ingredient)
                }
            }
            .sheet(isPresented: $showingAddInstruction) {
                AddInstructionSheet { instruction in
                    instructions.append(instruction)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveRecipe() {
        if let recipe = recipe {
            // Update existing recipe
            recipe.name = name
            recipe.recipeDescription = recipeDescription.isEmpty ? nil : recipeDescription
            recipe.prepTime = prepTime
            recipe.cookTime = cookTime
            recipe.servings = servings
            recipe.difficulty = difficulty
            recipe.isFavorite = isFavorite
            recipe.notes = notes.isEmpty ? nil : notes
            recipe.sourceURL = sourceURL.isEmpty ? nil : sourceURL
            recipe.imageData = selectedImageData
            recipe.modifiedDate = Date()
            
            // Clear and rebuild ingredients
            recipe.ingredients?.removeAll()
            for (index, ing) in ingredients.enumerated() {
                let ingredient = RecipeIngredient(
                    name: ing.name,
                    quantity: ing.quantity,
                    unit: ing.unit,
                    notes: ing.notes.isEmpty ? nil : ing.notes,
                    isOptional: ing.isOptional,
                    sortOrder: index
                )
                modelContext.insert(ingredient)
                recipe.ingredients?.append(ingredient)
            }
            
            // Clear and rebuild instructions
            recipe.instructions?.removeAll()
            for (index, inst) in instructions.enumerated() {
                let instruction = RecipeInstruction(
                    stepNumber: index + 1,
                    instruction: inst.instruction,
                    timerDuration: inst.timerDuration
                )
                modelContext.insert(instruction)
                recipe.instructions?.append(instruction)
            }
        } else {
            // Create new recipe
            let newRecipe = Recipe(
                name: name,
                description: recipeDescription.isEmpty ? nil : recipeDescription,
                imageData: selectedImageData,
                prepTime: prepTime,
                cookTime: cookTime,
                servings: servings,
                difficulty: difficulty,
                isFavorite: isFavorite,
                notes: notes.isEmpty ? nil : notes,
                sourceURL: sourceURL.isEmpty ? nil : sourceURL
            )
            
            modelContext.insert(newRecipe)
            
            // Add ingredients
            for (index, ing) in ingredients.enumerated() {
                let ingredient = RecipeIngredient(
                    name: ing.name,
                    quantity: ing.quantity,
                    unit: ing.unit,
                    notes: ing.notes.isEmpty ? nil : ing.notes,
                    isOptional: ing.isOptional,
                    sortOrder: index
                )
                modelContext.insert(ingredient)
                newRecipe.ingredients?.append(ingredient)
            }
            
            // Add instructions
            for (index, inst) in instructions.enumerated() {
                let instruction = RecipeInstruction(
                    stepNumber: index + 1,
                    instruction: inst.instruction,
                    timerDuration: inst.timerDuration
                )
                modelContext.insert(instruction)
                newRecipe.instructions?.append(instruction)
            }
        }
        
        dismiss()
    }
}

// MARK: - Ingredient Input Model
struct IngredientInput: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var notes: String
    var isOptional: Bool
}

// MARK: - Instruction Input Model
struct InstructionInput: Identifiable {
    let id = UUID()
    var instruction: String
    var timerDuration: Int?
}

// MARK: - Add Ingredient Sheet
struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (IngredientInput) -> Void
    
    @State private var name = ""
    @State private var quantity: Double = 1.0
    @State private var unit = "cup"
    @State private var notes = ""
    @State private var isOptional = false
    
    let commonUnits = ["cup", "tbsp", "tsp", "oz", "lb", "g", "kg", "mL", "L", "item", "pinch", "clove", "can"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient Details") {
                    TextField("Name", text: $name)
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(commonUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    
                    TextField("Notes (optional)", text: $notes)
                    
                    Toggle("Optional Ingredient", isOn: $isOptional)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let ingredient = IngredientInput(
                            name: name,
                            quantity: quantity,
                            unit: unit,
                            notes: notes,
                            isOptional: isOptional
                        )
                        onSave(ingredient)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Instruction Sheet
struct AddInstructionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (InstructionInput) -> Void
    
    @State private var instruction = ""
    @State private var hasTimer = false
    @State private var timerDuration: Int = 10
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Instruction Details") {
                    TextField("Instruction", text: $instruction, axis: .vertical)
                        .lineLimit(4...8)
                    
                    Toggle("Add Timer", isOn: $hasTimer)
                    
                    if hasTimer {
                        Stepper("Timer: \(timerDuration) min", value: $timerDuration, in: 1...180)
                    }
                }
            }
            .navigationTitle("Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let inst = InstructionInput(
                            instruction: instruction,
                            timerDuration: hasTimer ? timerDuration : nil
                        )
                        onSave(inst)
                        dismiss()
                    }
                    .disabled(instruction.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("New Recipe") {
    AddEditRecipeView()
        .modelContainer(for: Recipe.self, inMemory: true)
}

#Preview("Edit Recipe") {
    let container = try! ModelContainer(for: Recipe.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let recipe = Recipe.sampleRecipes[0]
    container.mainContext.insert(recipe)
    
    return AddEditRecipeView(recipe: recipe)
        .modelContainer(container)
}
