//
//  CookingModeView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct CookingModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var recipe: Recipe
    
    @State private var currentStepIndex = 0
    @State private var completedSteps: Set<Int> = []
    @State private var activeTimer: RecipeTimer?
    @State private var showingTimerSheet = false
    @State private var keepAwake = true
    
    private var sortedInstructions: [RecipeInstruction] {
        recipe.instructions?.sorted(by: { $0.stepNumber < $1.stepNumber }) ?? []
    }
    
    private var currentInstruction: RecipeInstruction? {
        guard currentStepIndex < sortedInstructions.count else { return nil }
        return sortedInstructions[currentStepIndex]
    }
    
    private var progress: Double {
        guard !sortedInstructions.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(sortedInstructions.count)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress Bar
                    ProgressView(value: progress)
                        .tint(.green)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Step Counter
                    Text("Step \(currentStepIndex + 1) of \(sortedInstructions.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current Instruction
                            if let instruction = currentInstruction {
                                instructionCard(instruction, geometry: geometry)
                            } else {
                                completionView
                            }
                            
                            // Navigation Buttons
                            navigationButtons
                            
                            // All Steps Overview (Collapsed)
                            allStepsSection
                        }
                        .padding()
                    }
                    
                    // Active Timer
                    if let timer = activeTimer {
                        activeTimerView(timer)
                    }
                }
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .bold()
                    }
                }
            }
            .sheet(isPresented: $showingTimerSheet) {
                if let instruction = currentInstruction, let duration = instruction.timerDuration {
                    TimerSheet(duration: duration) { timer in
                        activeTimer = timer
                    }
                }
            }
            .onAppear {
                // Keep screen awake
                UIApplication.shared.isIdleTimerDisabled = keepAwake
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
    
    // MARK: - View Components
    
    private func instructionCard(_ instruction: RecipeInstruction, geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            // Large step number
            Text("\(instruction.stepNumber)")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(completedSteps.contains(instruction.stepNumber) ? Color.green : Color.accentColor)
                )
            
            // Instruction text - Large and readable
            Text(instruction.instruction)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            // Timer button if available
            if let timerDuration = instruction.timerDuration {
                Button {
                    startTimer(duration: timerDuration)
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("\(timerDuration) minute timer")
                            .bold()
                    }
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            
            // Mark as complete button
            Button {
                withAnimation {
                    if completedSteps.contains(instruction.stepNumber) {
                        completedSteps.remove(instruction.stepNumber)
                    } else {
                        completedSteps.insert(instruction.stepNumber)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: completedSteps.contains(instruction.stepNumber) ? "checkmark.circle.fill" : "circle")
                    Text(completedSteps.contains(instruction.stepNumber) ? "Completed" : "Mark as Complete")
                        .bold()
                }
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity)
                .background(completedSteps.contains(instruction.stepNumber) ? Color.green : Color.gray.opacity(0.3))
                .foregroundStyle(completedSteps.contains(instruction.stepNumber) ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(minHeight: geometry.size.height * 0.5)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            // Previous Button
            Button {
                withAnimation {
                    if currentStepIndex > 0 {
                        currentStepIndex -= 1
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.title3)
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(currentStepIndex > 0 ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(currentStepIndex == 0)
            
            // Next Button
            Button {
                withAnimation {
                    if currentStepIndex < sortedInstructions.count - 1 {
                        currentStepIndex += 1
                    } else if currentStepIndex == sortedInstructions.count - 1 {
                        currentStepIndex += 1 // Move to completion view
                    }
                }
            } label: {
                HStack {
                    Text(currentStepIndex < sortedInstructions.count - 1 ? "Next" : "Finish")
                    Image(systemName: "chevron.right")
                }
                .font(.title3)
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
    
    private var allStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Steps")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(sortedInstructions) { instruction in
                Button {
                    withAnimation {
                        currentStepIndex = instruction.stepNumber - 1
                    }
                } label: {
                    HStack {
                        // Step indicator
                        ZStack {
                            Circle()
                                .fill(completedSteps.contains(instruction.stepNumber) ? Color.green : (currentStepIndex + 1 == instruction.stepNumber ? Color.accentColor : Color.gray.opacity(0.3)))
                                .frame(width: 32, height: 32)
                            
                            if completedSteps.contains(instruction.stepNumber) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                                    .bold()
                            } else {
                                Text("\(instruction.stepNumber)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(currentStepIndex + 1 == instruction.stepNumber ? .white : .secondary)
                            }
                        }
                        
                        // Instruction preview
                        Text(instruction.instruction)
                            .font(.subheadline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(currentStepIndex + 1 == instruction.stepNumber ? .primary : .secondary)
                        
                        Spacer()
                        
                        if instruction.timerDuration != nil {
                            Image(systemName: "timer")
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .background(currentStepIndex + 1 == instruction.stepNumber ? Color.accentColor.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 20)
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
            
            Text("Recipe Complete!")
                .font(.largeTitle)
                .bold()
            
            Text("Great job! You've completed all steps.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                dismiss()
            } label: {
                Text("Finish Cooking")
                    .font(.title3)
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Button {
                withAnimation {
                    currentStepIndex = 0
                    completedSteps.removeAll()
                }
            } label: {
                Text("Start Over")
                    .font(.headline)
                    .foregroundStyle(.accentColor)
            }
        }
        .padding()
    }
    
    private func activeTimerView(_ timer: RecipeTimer) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                
                Text(timer.remainingTimeString)
                    .font(.title2)
                    .bold()
                    .monospacedDigit()
                
                Spacer()
                
                Button {
                    timer.pause()
                } label: {
                    Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                }
                .font(.title3)
                
                Button {
                    activeTimer = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .font(.title3)
            }
            .padding()
            .background(Color.orange)
            .foregroundStyle(.white)
            
            ProgressView(value: timer.progress)
                .tint(.white)
        }
    }
    
    // MARK: - Actions
    
    private func startTimer(duration: Int) {
        let timer = RecipeTimer(duration: duration * 60) // Convert to seconds
        activeTimer = timer
        timer.start()
    }
}

// MARK: - Recipe Timer
@Observable
class RecipeTimer {
    var duration: Int // in seconds
    var remainingTime: Int
    var isPaused = false
    private var timer: Timer?
    
    init(duration: Int) {
        self.duration = duration
        self.remainingTime = duration
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return 1.0 - (Double(remainingTime) / Double(duration))
    }
    
    var remainingTimeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func start() {
        isPaused = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.timer?.invalidate()
                // TODO: Trigger notification or sound
            }
        }
    }
    
    func pause() {
        isPaused.toggle()
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Timer Sheet
struct TimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let duration: Int
    let onStart: (RecipeTimer) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                
                Text("\(duration) minutes")
                    .font(.largeTitle)
                    .bold()
                
                Text("Start the timer for this step?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Button {
                    let timer = RecipeTimer(duration: duration * 60)
                    onStart(timer)
                    timer.start()
                    dismiss()
                } label: {
                    Text("Start Timer")
                        .font(.title3)
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(for: Recipe.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let recipe = Recipe.sampleRecipes[0]
    
    // Add some sample instructions
    let inst1 = RecipeInstruction(stepNumber: 1, instruction: "Boil water in a large pot. Add a generous amount of salt.", timerDuration: 10)
    let inst2 = RecipeInstruction(stepNumber: 2, instruction: "Add pasta and cook according to package directions, usually 8-10 minutes.", timerDuration: 10)
    let inst3 = RecipeInstruction(stepNumber: 3, instruction: "While pasta cooks, whisk together eggs and cheese in a bowl.")
    let inst4 = RecipeInstruction(stepNumber: 4, instruction: "Drain pasta, reserving 1 cup of pasta water. Toss with egg mixture immediately.")
    
    recipe.instructions = [inst1, inst2, inst3, inst4]
    container.mainContext.insert(recipe)
    container.mainContext.insert(inst1)
    container.mainContext.insert(inst2)
    container.mainContext.insert(inst3)
    container.mainContext.insert(inst4)
    
    return CookingModeView(recipe: recipe)
        .modelContainer(container)
}
