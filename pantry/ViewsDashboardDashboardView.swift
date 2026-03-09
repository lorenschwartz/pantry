//
//  DashboardView.swift
//  pantry
//
//  AI-first home dashboard with proactive proposal cards.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var assistantSession: AssistantSessionStore

    @Query private var pantryItems: [PantryItem]
    @Query(sort: \ShoppingListItem.priority, order: .reverse) private var shoppingItems: [ShoppingListItem]
    @Query private var recipes: [Recipe]
    @Query(sort: \MealPlan.startDate, order: .reverse) private var mealPlans: [MealPlan]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showMoreMenu = false
    @State private var dismissedProposalIDs = Set<String>()
    @State private var pendingConfirmation: CopilotProposal?
    @State private var actionStatusMessage: String?

    private var activePantryItems: [PantryItem] {
        pantryItems.filter { !$0.isArchived }
    }

    private var expiringSoonItems: [PantryItem] {
        activePantryItems
            .filter { $0.isExpiringSoon && !$0.isExpired }
            .sorted { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
    }

    private var lowStockItems: [PantryItem] {
        LowStockService.detectLowStockItems(from: activePantryItems)
    }

    private var pendingShoppingItems: [ShoppingListItem] {
        shoppingItems.filter { !$0.isChecked }
    }

    private var activeMealPlan: MealPlan? {
        mealPlans.first(where: { $0.includes(Date()) })
    }

    private var suggestedTopRecipe: (recipe: Recipe, matchPercentage: Double, missingIngredients: [RecipeIngredient])? {
        RecipePantryService.makeableRecipes(recipes: recipes, pantryItems: activePantryItems)
            .sorted { $0.matchPercentage > $1.matchPercentage }
            .first
    }

    private var restockCandidates: [PantryItem] {
        let namesOnShoppingList = Set(pendingShoppingItems.map { $0.name.lowercased() })
        return lowStockItems.filter { !namesOnShoppingList.contains($0.name.lowercased()) }
    }

    private var briefingHeadline: String {
        var segments: [String] = []
        if !expiringSoonItems.isEmpty {
            segments.append("\(expiringSoonItems.count) expiring soon")
        }
        if !restockCandidates.isEmpty {
            segments.append("\(restockCandidates.count) low-stock to restock")
        }
        if activeMealPlan == nil {
            segments.append("no active weekly plan")
        }
        if segments.isEmpty {
            return "Everything looks stable today. No urgent pantry risks detected."
        }
        return "Today: " + segments.joined(separator: " • ")
    }

    private var proposals: [CopilotProposal] {
        var generated: [CopilotProposal] = []

        if !restockCandidates.isEmpty {
            generated.append(
                CopilotProposal(
                    id: "restock-low-stock",
                    title: "Restock low-stock items",
                    detail: "Add \(restockCandidates.count) low-stock pantry item(s) to shopping list.",
                    impact: "Creates shopping entries",
                    requiresConfirmation: false,
                    action: .restockLowStock
                )
            )
        }

        if activeMealPlan == nil {
            generated.append(
                CopilotProposal(
                    id: "create-weekly-plan",
                    title: "Generate this week's meal plan",
                    detail: "Create a 7-day dinner plan using your current pantry and recipe library.",
                    impact: "Creates a new meal plan",
                    requiresConfirmation: true,
                    action: .createWeeklyPlan
                )
            )
        }

        if !expiringSoonItems.isEmpty {
            generated.append(
                CopilotProposal(
                    id: "expiring-item-plan",
                    title: "Prioritize expiring ingredients",
                    detail: "Build a weekly plan focused on using expiring items first.",
                    impact: "Creates/updates meal plan",
                    requiresConfirmation: true,
                    action: .generateWeeklyExpiringPlan
                )
            )
        }

        if let top = suggestedTopRecipe, top.matchPercentage < 100, !top.missingIngredients.isEmpty {
            generated.append(
                CopilotProposal(
                    id: "shop-for-top-recipe-\(top.recipe.id.uuidString)",
                    title: "Complete ingredients for \(top.recipe.name)",
                    detail: "Add \(top.missingIngredients.count) missing ingredient(s) for tonight's best-match recipe.",
                    impact: "Adds shopping list items",
                    requiresConfirmation: false,
                    action: .addMissingForRecipe(top.recipe.id)
                )
            )
        }

        return generated.filter { !dismissedProposalIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DashboardGreetingView(itemCount: activePantryItems.count)
                        .padding(.horizontal)

                    DashboardBriefingBanner(headline: briefingHeadline)
                        .padding(.horizontal)

                    DashboardStatsRow(
                        totalItems: activePantryItems.count,
                        expiringSoon: expiringSoonItems.count,
                        shoppingPending: pendingShoppingItems.count,
                        lowStock: lowStockItems.count
                    )
                    .padding(.horizontal)

                    if !proposals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Copilot Proposals")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(proposals) { proposal in
                                CopilotProposalCard(
                                    proposal: proposal,
                                    onApprove: { handleApprove(proposal) },
                                    onDismiss: { dismissedProposalIDs.insert(proposal.id) }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }

                    DashboardAISection(
                        pantryItems: activePantryItems,
                        recipes: recipes,
                        assistantSession: assistantSession
                    )
                        .padding(.horizontal)

                    if let plan = activeMealPlan {
                        DashboardSectionHeader(title: "Active Meal Plan") {
                            MealPlanListView()
                        }
                        .padding(.horizontal)

                        ActiveMealPlanCard(mealPlan: plan)
                            .padding(.horizontal)
                    }

                    if let top = suggestedTopRecipe {
                        DashboardSectionHeader(title: "Top Recipe Match") {
                            RecipeSuggestionsView()
                        }
                        .padding(.horizontal)

                        TopRecipeMatchCard(
                            recipe: top.recipe,
                            matchPercentage: top.matchPercentage,
                            missingCount: top.missingIngredients.count
                        )
                        .padding(.horizontal)
                    }

                    DashboardQuickActions(assistantSession: assistantSession)
                        .padding(.horizontal)

                    if let actionStatusMessage {
                        Text(actionStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button {
                    showMoreMenu = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .padding(12)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
            .sheet(isPresented: $showMoreMenu) {
                MoreMenuView(assistantSession: assistantSession)
            }
            .confirmationDialog(
                pendingConfirmation?.title ?? "Approve Copilot Action",
                isPresented: Binding(
                    get: { pendingConfirmation != nil },
                    set: { if !$0 { pendingConfirmation = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Approve") {
                    if let proposal = pendingConfirmation {
                        execute(proposal)
                    }
                    pendingConfirmation = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingConfirmation = nil
                }
            } message: {
                Text(pendingConfirmation?.detail ?? "")
            }
        }
    }

    private func handleApprove(_ proposal: CopilotProposal) {
        if proposal.requiresConfirmation {
            pendingConfirmation = proposal
            return
        }
        execute(proposal)
    }

    private func execute(_ proposal: CopilotProposal) {
        switch proposal.action {
        case .restockLowStock:
            let added = LowStockService.addToShoppingList(
                restockCandidates,
                existingList: pendingShoppingItems,
                context: modelContext
            )
            try? modelContext.save()
            actionStatusMessage = "Added \(added.count) low-stock item(s) to shopping list."

        case .createWeeklyPlan:
            generateWeeklyPlan(prioritizeExpiring: false)
            actionStatusMessage = "Created a new weekly dinner plan."

        case .generateWeeklyExpiringPlan:
            generateWeeklyPlan(prioritizeExpiring: true)
            actionStatusMessage = "Created a weekly plan prioritizing expiring ingredients."

        case .addMissingForRecipe(let recipeID):
            guard let recipe = recipes.first(where: { $0.id == recipeID }) else { return }
            let generated = RecipePantryService.generateShoppingList(
                recipe: recipe,
                pantryItems: activePantryItems,
                categories: categories
            )
            let existingNames = Set(pendingShoppingItems.map { $0.name.lowercased() })
            let toInsert = generated.filter { !existingNames.contains($0.name.lowercased()) }
            for item in toInsert {
                modelContext.insert(item)
            }
            try? modelContext.save()
            actionStatusMessage = "Added \(toInsert.count) missing ingredient(s) for \(recipe.name)."
        }

        dismissedProposalIDs.insert(proposal.id)
    }

    private func generateWeeklyPlan(prioritizeExpiring: Bool) {
        if let plan = activeMealPlan {
            for existing in plan.entries ?? [] {
                modelContext.delete(existing)
            }
            plan.entries = []
            plan.modifiedDate = Date()

            let request = MealPlanRequest(
                startDate: Date(),
                days: 7,
                mealTypes: [.dinner],
                prioritizeExpiring: prioritizeExpiring,
                desiredServings: 2
            )
            let draft = MealPlanService.generateDraft(request: request, recipes: recipes, pantryItems: activePantryItems)
            insertMealPlanEntries(draft, into: plan)
            try? modelContext.save()
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let plan = MealPlan(name: "Copilot Week Plan", startDate: start, endDate: end)
        modelContext.insert(plan)

        let request = MealPlanRequest(
            startDate: start,
            days: 7,
            mealTypes: [.dinner],
            prioritizeExpiring: prioritizeExpiring,
            desiredServings: 2
        )
        let draft = MealPlanService.generateDraft(request: request, recipes: recipes, pantryItems: activePantryItems)
        insertMealPlanEntries(draft, into: plan)
        try? modelContext.save()
    }

    private func insertMealPlanEntries(_ draft: [MealPlanDraftEntry], into plan: MealPlan) {
        for (index, item) in draft.enumerated() {
            let entry = MealPlanEntry(
                date: item.date,
                mealType: item.mealType,
                status: .planned,
                servingsOverride: item.servingsOverride,
                position: index,
                confidence: item.confidence,
                recipe: item.recipe
            )
            let reason = MealPlanEntryReason(
                summary: item.rationale,
                pantryCoverage: item.pantryCoverage
            )
            reason.entry = entry
            entry.reason = reason
            entry.mealPlan = plan
            modelContext.insert(reason)
            modelContext.insert(entry)
        }
    }
}

private struct DashboardGreetingView: View {
    let itemCount: Int

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var dateString: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title.bold())
            Text("\(dateString) • \(itemCount) active pantry items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DashboardBriefingBanner: View {
    let headline: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Copilot Daily Briefing", systemImage: "sparkles.rectangle.stack")
                .font(.headline)
            Text(headline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.18), Color.blue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct DashboardStatsRow: View {
    let totalItems: Int
    let expiringSoon: Int
    let shoppingPending: Int
    let lowStock: Int

    var body: some View {
        HStack(spacing: 10) {
            StatPill(value: "\(totalItems)", label: "Items", icon: "cabinet", color: .blue)
            StatPill(value: "\(expiringSoon)", label: "Expiring", icon: "clock", color: .orange)
            StatPill(value: "\(shoppingPending)", label: "Shopping", icon: "cart", color: .green)
            StatPill(value: "\(lowStock)", label: "Low Stock", icon: "arrow.down.circle", color: .red)
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct DashboardSectionHeader<Destination: View>: View {
    let title: String
    let destination: Destination

    init(title: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.destination = destination()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            NavigationLink(destination: destination) {
                Text("See all")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }
}

private enum CopilotProposalAction: Hashable {
    case restockLowStock
    case createWeeklyPlan
    case generateWeeklyExpiringPlan
    case addMissingForRecipe(UUID)
}

private struct CopilotProposal: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let impact: String
    let requiresConfirmation: Bool
    let action: CopilotProposalAction
}

private struct CopilotProposalCard: View {
    let proposal: CopilotProposal
    let onApprove: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.title)
                        .font(.headline)
                    Text(proposal.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if proposal.requiresConfirmation {
                    Text("Confirm")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            Text("Impact: \(proposal.impact)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                Spacer()
                Button("Approve", action: onApprove)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct DashboardAISection: View {
    @Environment(\.modelContext) private var modelContext

    let pantryItems: [PantryItem]
    let recipes: [Recipe]
    @Bindable var assistantSession: AssistantSessionStore

    private let promptChips = [
        "What can I make tonight?",
        "What's expiring soon?",
        "Build me a weeknight meal plan",
        "How can I reduce grocery waste this week?"
    ]

    private var chipColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 8)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.indigo)
                Text("Copilot Console")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ChatView(session: assistantSession)) {
                    Label("Open Assistant", systemImage: "arrow.right.circle")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                }
            }

            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                ForEach(promptChips, id: \.self) { chip in
                    Button { assistantSession.draftMessage = chip } label: {
                        Text(chip)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)
                }
            }

            HStack(spacing: 10) {
                TextField("Ask anything about your pantry…", text: $assistantSession.draftMessage, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    sendQuery()
                } label: {
                    Group {
                        if assistantSession.service.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.up").fontWeight(.bold)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        assistantSession.draftMessage
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty ? Color.secondary : Color.indigo
                    )
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                }
                .disabled(
                    assistantSession.draftMessage
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty || assistantSession.service.isLoading
                )
            }

            if !assistantSession.service.chatMessages.isEmpty {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(assistantSession.service.chatMessages.suffix(6)) { message in
                            ChatBubbleView(message: message)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)
                .background(Color.indigo.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.09), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.2), value: assistantSession.service.chatMessages.count)
    }

    private func sendQuery() {
        let trimmed = assistantSession.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task {
            await assistantSession.sendDraft(context: modelContext)
        }
    }
}

private struct ActiveMealPlanCard: View {
    let mealPlan: MealPlan

    private var plannedCount: Int {
        (mealPlan.entries ?? []).filter { $0.status == .planned }.count
    }

    private var cookedCount: Int {
        (mealPlan.entries ?? []).filter { $0.status == .cooked }.count
    }

    var body: some View {
        NavigationLink(destination: MealPlanDetailView(mealPlan: mealPlan)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(mealPlan.name)
                    .font(.headline)
                Text("\(plannedCount) planned • \(cookedCount) cooked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct TopRecipeMatchCard: View {
    let recipe: Recipe
    let matchPercentage: Double
    let missingCount: Int

    var body: some View {
        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                    Text("\(Int(matchPercentage))% pantry match")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if missingCount > 0 {
                        Text("\(missingCount) ingredient(s) missing")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardQuickActions: View {
    @Bindable var assistantSession: AssistantSessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 10) {
                NavigationLink(destination: ChatView(session: assistantSession)) {
                    QuickActionTile(icon: "sparkles", label: "Open\nAssistant", color: .indigo)
                }
                NavigationLink(destination: MealPlanListView()) {
                    QuickActionTile(icon: "calendar", label: "Meal\nPlans", color: .mint)
                }
                NavigationLink(destination: RecipeSuggestionsView()) {
                    QuickActionTile(icon: "fork.knife", label: "Recipe\nMatches", color: .orange)
                }
                NavigationLink(destination: ReceiptsListView(showingSourcePicker: .constant(false))) {
                    QuickActionTile(icon: "doc.text.viewfinder", label: "Scan\nReceipt", color: .teal)
                }
            }
        }
    }
}

private struct QuickActionTile: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PantryItem.self, ShoppingListItem.self, Recipe.self,
        Category.self, StorageLocation.self,
        RecipeIngredient.self, RecipeInstruction.self,
        MealPlan.self, MealPlanEntry.self, MealPlanEntryReason.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    SampleDataService.loadSampleData(into: container.mainContext)

    return DashboardView(assistantSession: AssistantSessionStore())
        .modelContainer(container)
}
