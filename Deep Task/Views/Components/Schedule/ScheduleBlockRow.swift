//
//  ScheduleBlockRow.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import SwiftUI

// A single timeline row in the planner: time range on the left, block details on the right.
struct ScheduleBlockRow: View {
    let block: ScheduleBlock
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared

    private var taskCount: Int {
        persistenceManager.getTasks(forBlock: block.id).count
    }

    private var completedTaskCount: Int {
        persistenceManager.getTasks(forBlock: block.id).filter { $0.isComplete }.count
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatMinutesAsTime(block.startMinutes))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text(formatMinutesAsTime(block.endMinutes))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(width: 72, alignment: .trailing)

            // Vertical accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.orange.opacity(0.8))
                .frame(width: 4)

            // Block content card
            VStack(alignment: .leading, spacing: 6) {
                Text(block.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(formatDurationMinutes(block.durationMinutes))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.square")
                            .font(.system(size: 11))
                        Text(taskCount == 0 ? "No tasks" : "\(completedTaskCount)/\(taskCount) tasks")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
