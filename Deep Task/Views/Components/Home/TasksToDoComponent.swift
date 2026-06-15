//
//  TasksToDoComponent.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import SwiftUI

struct TaskToDoComponent: View {
    let taskTitle: String
    let numberOfTasks: Int
    let tasksCompleted: Int
    let duration: Int // Duration in minutes
    let dateCompleted: Date?

    private var isComplete: Bool {
        dateCompleted != nil || (numberOfTasks > 0 && tasksCompleted >= numberOfTasks)
    }

    // Completion fraction 0...1 for the progress ring.
    private var progress: Double {
        guard numberOfTasks > 0 else { return 0 }
        return Double(tasksCompleted) / Double(numberOfTasks)
    }

    // Ring colors: green when finished, warm brand gradient while in progress.
    private var ringColors: [Color] {
        isComplete ? [.green, .green] : [.orange, .red]
    }

    // Convert minutes to readable format.
    private var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m allocated"
        } else if hours > 0 {
            return "\(hours)h allocated"
        } else {
            return "\(minutes)m allocated"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Title + meta
            VStack(alignment: .leading, spacing: 8) {
                Text(taskTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: isComplete ? "checkmark.seal.fill" : "clock")
                        .foregroundStyle(isComplete ? .green : .secondary)
                        .font(.system(size: 12))

                    Text(dateCompleted != nil
                         ? "Completed on \(formatDateToLocalString(dateCompleted!))"
                         : formattedDuration)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            // Progress ring with count in the center
            ZStack {
                ProgressRing(progress: progress, colors: ringColors, lineWidth: 6, size: 56)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text("\(tasksCompleted)/\(numberOfTasks)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
        .padding(.leading, 22)
        .contentCard()
        // Leading accent bar, bounded to the card's content height.
//        .overlay(alignment: .leading) {
//            Capsule()
//                .fill(LinearGradient(colors: ringColors, startPoint: .top, endPoint: .bottom))
//                .frame(width: 5)
//                .padding(.vertical, 14)
//                .padding(.leading, 8)
//        }
    }
}

// A circular progress ring with a gradient stroke.
struct ProgressRing: View {
    let progress: Double          // 0...1
    var colors: [Color] = [.orange, .red]
    var lineWidth: CGFloat = 6
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 16) {
        TaskToDoComponent(taskTitle: "Capex Report for Board Meeting", numberOfTasks: 5, tasksCompleted: 2, duration: 75, dateCompleted: nil)

        TaskToDoComponent(taskTitle: "Morning Reading", numberOfTasks: 3, tasksCompleted: 3, duration: 45, dateCompleted: Date())
    }
    .padding()
    .background(Color(.systemGray6))
}
