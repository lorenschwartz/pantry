//
//  DashboardView.swift
//  pantry
//
//  Root landing screen. Replaces the old Insights tab and gives an at-a-glance
//  summary of the pantry alongside an AI assistant input that the LLM session
//  can wire up.
//

import SwiftUI
import SwiftData

// MARK: - Main View

struct DashboardView: View {
    @Query private var pantryItems: [PantryItem]
    @Query(sort: \ShoppingListItem.priority, order: .reverse) private var shoppingItems: [ShoppingListItem]
    @Query private var recipes: [Recipe]
    @State private var showMoreMenu = false

    // MARK: Derived data

    private var expiringSoonItems: [PantryItem] {
        pantryItems
            .filter { $0.isExpiringSoon && !$0.isExpired && !$0.isArchived }
            .sorted { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
    }

    private var lowStockItems: [PantryItem] {
        LowStockService.detectLowStockItems(from: pantryItems)
    }

    private var pendingShoppingItems: [ShoppingListItem] {
        shoppingItems.filter { !$0.isChecked }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Greeting ──────────────────────────────────────────
                    DashboardGreetingView(itemCount: pantryItems.filter { !$0.isArchived }.count)
                        .padding(.horizontal)

                    // ── Stats row ─────────────────────────────────────────
                    DashboardStatsRow(
                        totalItems: pantryItems.filter { !$0.isArchived }.count,
                        expiringSoon: expiringSoonItems.count,
                        shoppingPending: pendingShoppingItems.count,
                        lowStock: lowStockItems.count
                    )
                    .padding(.horizontal)

                    // ── AI Assistant ──────────────────────────────────────
                    DashboardAISection(
                        pantryItems: pantryItems,
                        recipes: recipes
                    )
                    .padding(.horizontal)

                    // ── Expiring soon ─────────────────────────────────────
                    if !expiringSoonItems.isEmpty {
                        DashboardSectionHeader(title: "Use Soon", destination: AnyView(ExpiringItemsView(items: expiringSoonItems)))
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(expiringSoonItems.prefix(8)) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        ExpiringItemCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // ── Quick actions ─────────────────────────────────────
                    DashboardQuickActions()
                        .padding(.horizontal)

                    // ── Shopping list preview ─────────────────────────────
                    if !pendingShoppingItems.isEmpty {
                        DashboardSectionHeader(
                            title: "Shopping List",
                            destination: AnyView(ShoppingListView(showAddItem: .constant(false)))
                        )
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(pendingShoppingItems.prefix(4)) { item in
                                DashboardShoppingRow(item: item)
                                if item.id != pendingShoppingItems.prefix(4).last?.id {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                MoreMenuView()
            }
        }
    }
}

// MARK: - Greeting

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
            Text(dateString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Stats row

private struct DashboardStatsRow: View {
    let totalItems: Int
    let expiringSoon: Int
    let shoppingPending: Int
    let lowStock: Int

    var body: some View {
        HStack(spacing: 10) {
            StatPill(value: "\(totalItems)", label: "Items",    icon: "cabinet",                   color: .blue)
            StatPill(value: "\(expiringSoon)", label: "Expiring", icon: "clock",                   color: .orange)
            StatPill(value: "\(shoppingPending)", label: "Shopping", icon: "cart",                 color: .green)
            StatPill(value: "\(lowStock)",  label: "Low Stock", icon: "arrow.down.circle",         color: .red)
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

// MARK: - Section header

private struct DashboardSectionHeader<Dest: View>: View {
    let title: String
    let destination: Dest

    init(title: String, destination: AnyView) where Dest == AnyView {
        self.title = title
        self.destination = destination as! Dest
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

// MARK: - Expiring item card

private struct ExpiringItemCard: View {
    let item: PantryItem

    private var urgency: Color {
        guard let d = item.daysUntilExpiration else { return .green }
        if d <= 1 { return .red }
        if d <= 3 { return .orange }
        return .yellow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let cat = item.category {
                Image(systemName: cat.iconName)
                    .font(.title2)
                    .foregroundStyle(cat.color)
            } else {
                Image(systemName: "cube.box")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.name)
                .font(.subheadline.bold())
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let d = item.daysUntilExpiration {
                Text(d == 0 ? "Today" : d == 1 ? "Tomorrow" : "in \(d)d")
                    .font(.caption)
                    .foregroundStyle(urgency)
            }
        }
        .padding(12)
        .frame(width: 110, height: 110)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(urgency.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - AI Assistant section

struct DashboardAISection: View {
    @Environment(\.modelContext) private var modelContext

    let pantryItems: [PantryItem]
    let recipes: [Recipe]

    @State private var service = LLMService()
    @State private var query = ""
    @State private var response: String? = nil
    @State private var isLoading = false

    private let promptChips = [
        "What can I make tonight?",
        "What's expiring soon?",
        "Suggest a healthy meal",
        "Help me plan the week",
    ]

    private var chipColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 8)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Ask Your Pantry")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ChatView()) {
                    Label("Open Assistant", systemImage: "arrow.right.circle")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }

            // Prompt chips (wrapping grid, no horizontal scrolling)
            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                ForEach(promptChips, id: \.self) { chip in
                    Button {
                        query = chip
                    } label: {
                        Text(chip)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                }
            }

            // Input row
            HStack(spacing: 10) {
                TextField("Ask anything about your pantry…", text: $query, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    sendQuery()
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(query.isEmpty ? Color.secondary : Color.purple)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                }
                .disabled(query.isEmpty || isLoading)
            }

            // Response area
            if let response {
                ScrollView(.vertical, showsIndicators: true) {
                    Text(response)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)
                .background(Color.purple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))

                HStack {
                    Spacer()
                    NavigationLink(destination: ChatView()) {
                        Label("Continue in Assistant", systemImage: "arrow.right.circle")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.07), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.2), value: response)
    }

    private func sendQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        response = nil

        Task {
            // Dashboard asks are intentionally one-shot and concise for speed.
            service.clearConversation()
            let dashboardPrompt = """
            \(trimmed)

            Keep your answer concise (max 120 words) and practical.
            """

            await service.sendMessage(dashboardPrompt, context: modelContext)
            response = service.chatMessages.last(where: { $0.role == .assistant })?.content
                ?? "No response from assistant."
            query = ""
            isLoading = false
        }
    }
}

// MARK: - Quick actions

private struct DashboardQuickActions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 10) {
                NavigationLink(destination: RecipeSuggestionsView()) {
                    QuickActionTile(icon: "fork.knife", label: "What can\nI make?", color: .orange)
                }
                NavigationLink(destination: PantryListView(showAddItem: .constant(false))) {
                    QuickActionTile(icon: "cabinet", label: "Browse\nPantry", color: .blue)
                }
                NavigationLink(destination: ShoppingListView(showAddItem: .constant(false))) {
                    QuickActionTile(icon: "cart.badge.plus", label: "Shopping\nList", color: .green)
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

// MARK: - Shopping preview row

private struct DashboardShoppingRow: View {
    let item: ShoppingListItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.priority == 2 ? "exclamationmark.circle.fill" : "circle")
                .foregroundStyle(item.priority == 2 ? .red : .secondary)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                Text("\(item.quantity.formatted()) \(item.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let price = item.estimatedPrice {
                Text("≈ $\(price, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: PantryItem.self, ShoppingListItem.self, Recipe.self,
        Category.self, StorageLocation.self,
        RecipeIngredient.self, RecipeInstruction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    SampleDataService.loadSampleData(into: container.mainContext)

    return DashboardView()
        .modelContainer(container)
}
