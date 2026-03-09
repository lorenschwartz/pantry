//
//  ViewsMealPlanMealPlanEntryCard.swift
//  pantry
//

import SwiftUI

struct MealPlanEntryCard: View {
    let entry: MealPlanEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.mealType.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.status.rawValue.capitalized)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBackground)
                    .clipShape(Capsule())
            }

            Text(entry.recipe?.name ?? "Unassigned")
                .font(.headline)

            HStack(spacing: 8) {
                Label("\(Int(entry.confidence * 100))% confidence", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(entry.isHighConfidence ? .green : .orange)
                if let coverage = entry.reason?.pantryCoverage {
                    Label("\(Int(coverage * 100))% pantry", systemImage: "cabinet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let summary = entry.reason?.summary, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusBackground: Color {
        switch entry.status {
        case .planned: return .blue.opacity(0.15)
        case .cooked: return .green.opacity(0.15)
        case .skipped: return .gray.opacity(0.2)
        }
    }
}

