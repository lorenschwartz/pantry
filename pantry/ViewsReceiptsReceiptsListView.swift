//
//  ReceiptsListView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-22.
//

import SwiftUI
import SwiftData

struct ReceiptsListView: View {
    @Query private var receipts: [Receipt]
    
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Receipts",
                systemImage: "doc.text",
                description: Text("Receipt scanning coming in Phase 3")
            )
            .navigationTitle("Receipts")
        }
    }
}

#Preview {
    ReceiptsListView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
