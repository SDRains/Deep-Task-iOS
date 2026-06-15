//
//  WeekAtAGlanceView.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/11/26.
//

import SwiftUI

// A full-screen overview of the current week. Each day shows how many tasks
// (and blocks) are scheduled, using the day's default scope. Tapping a day
// jumps the planner to it.
struct WeekAtAGlanceView: View {
    @Environment(\.dismiss) private var dismiss

    // Called with the chosen day so the planner can navigate to it.
    var onSelectDay: (Date) -> Void

    @ObservedObject private var scheduleManager = SchedulePersistenceManager.shared
    @ObservedObject private var taskManager = TaskPersistenceManager.shared

    private let calendar = Calendar.current

    // The seven days of the week containing today.
    private var weekDays: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
    }

    private var weekRangeLabel: String {
        guard let start = weekDays.first, let end = weekDays.last else { return "" }
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "MMM d"

        let endFormatter = DateFormatter()
        // Repeat the month only when the week spans two months.
        endFormatter.dateFormat = calendar.isDate(start, equalTo: end, toGranularity: .month) ? "d" : "MMM d"

        return "\(startFormatter.string(from: start)) – \(endFormatter.string(from: end))"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(weekDays, id: \.self) { day in
                        Button {
                            onSelectDay(calendar.startOfDay(for: day))
                            dismiss()
                        } label: {
                            dayRow(for: day)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
        }
        .background(Color(.systemGray6))
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Week")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(weekRangeLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.22)))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.brandGradient.ignoresSafeArea(edges: .top))
    }

    // MARK: - Day row

    private func dayRow(for day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let blocks = scheduleManager.blocks(for: scheduleManager.defaultScope(on: day))
        let taskCount = blocks.reduce(0) { $0 + taskManager.getTasks(forBlock: $1.id).count }
        let blockCount = blocks.count

        return HStack(spacing: 16) {
            // Date badge
            VStack(spacing: 1) {
                Text(weekdayShort(day))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isToday ? .white.opacity(0.9) : .secondary)
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isToday ? .white : .primary)
            }
            .frame(width: 52, height: 52)
            .background {
                if isToday {
                    AppTheme.brandGradient
                } else {
                    Color(.systemGray5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Weekday + block count
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayFull(day))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(blockCount == 0
                     ? "Nothing scheduled"
                     : "\(blockCount) \(blockCount == 1 ? "block" : "blocks")")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Task count
            VStack(spacing: 0) {
                Text("\(taskCount)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(taskCount > 0 ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(Color.secondary))
                Text(taskCount == 1 ? "task" : "tasks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .contentCard(addBorder: isToday)
    }

    // MARK: - Helpers

    private func weekdayShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func weekdayFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

#Preview {
    WeekAtAGlanceView(onSelectDay: { _ in })
}
