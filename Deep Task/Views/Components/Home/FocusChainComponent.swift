//
//  FocusChainComponent.swift
//  Deep Task
//
//  Created by Stephen Rains on 9/5/25.
//

import SwiftUI

struct FocusChainComponent: View {
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared

    var body: some View {
        let completionStats = getTaskCompletionStats(from: persistenceManager.getAllTasks())

        VStack(alignment: .leading, spacing: 12) {
            Text("Track your daily progression")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 4)

            VStack(spacing: 10) {
                FocusStatRow(
                    icon: "sun.max.fill",
                    color: .orange,
                    count: completionStats.completedToday,
                    timeframe: "today"
                )
                FocusStatRow(
                    icon: "moon.stars.fill",
                    color: .indigo,
                    count: completionStats.completedYesterday,
                    timeframe: "yesterday"
                )
                FocusStatRow(
                    icon: "calendar",
                    color: .green,
                    count: completionStats.completedThisMonth,
                    timeframe: "this month"
                )
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// A single progress row: tinted icon + a sentence highlighting the count.
private struct FocusStatRow: View {
    let icon: String
    let color: Color
    let count: Int
    let timeframe: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(Circle().fill(color.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) \(count == 1 ? "task" : "tasks")")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("completed \(timeframe)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentCard()
    }
}

#Preview {
    FocusChainComponent()
        .padding(.vertical)
        .background(Color(.systemGray6))
}
