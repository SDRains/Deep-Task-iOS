//
//  CompletedPage.swift
//  Deep Task
//
//  Created by Stephen Rains on 9/5/25.
//

import SwiftUI

struct CompletedPage: View {
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared
    @State private var taskToDelete: MainTask?

    private let calendar = Calendar.current

    // MARK: - Data

    private var completedTasks: [MainTask] {
        persistenceManager.getCompletedTasks()
    }

    // Effective completion date for a task (falls back to creation date if missing).
    private func completionDate(of task: MainTask) -> Date {
        task.dateCompleted ?? task.dateCreated
    }

    // Tasks grouped by calendar day, newest day first and newest task first within a day.
    private var groupedByDay: [(date: Date, tasks: [MainTask])] {
        let groups = Dictionary(grouping: completedTasks) { task in
            calendar.startOfDay(for: completionDate(of: task))
        }
        return groups
            .map { (date: $0.key,
                    tasks: $0.value.sorted { completionDate(of: $0) > completionDate(of: $1) }) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Stats

    private var totalCompleted: Int { completedTasks.count }

    private var completedToday: Int {
        completedTasks.filter { calendar.isDateInToday(completionDate(of: $0)) }.count
    }

    private var completedThisWeek: Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return completedTasks.filter { week.contains(completionDate(of: $0)) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if completedTasks.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        statsHeader

                        ForEach(groupedByDay, id: \.date) { group in
                            daySection(date: group.date, tasks: group.tasks)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .taskSwipeContainer()
            .confirmTaskDeletion($taskToDelete) { task in
                var props = AnalyticsService.shared.taskProperties(task)
                props["source"] = "Completed"
                AnalyticsService.shared.track("Task Deleted", properties: props)
                persistenceManager.deleteTask(withId: task.id)
            }
//            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .background(Color(.systemGray6))
            .navigationTitle("Completed")
            .onAppear {
                AnalyticsService.shared.trackScreen(.completed, properties: [
                    "completedToday": completedToday,
                    "completedThisWeek": completedThisWeek,
                    "totalCompleted": totalCompleted
                ])
            }
        }
    }

    // MARK: - Subviews

    private var statsHeader: some View {
        HStack(spacing: 12) {
            StatCard(icon: "checkmark.seal.fill", value: "\(completedToday)", label: "Today", color: .orange)
            StatCard(icon: "calendar", value: "\(completedThisWeek)", label: "This Week", color: .blue)
            StatCard(icon: "trophy.fill", value: "\(totalCompleted)", label: "All Time", color: .green)
        }
    }

    private func daySection(date: Date, tasks: [MainTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateLabel(for: date))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(tasks.count) \(tasks.count == 1 ? "task" : "tasks")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            ForEach(tasks) { mainTask in
                NavigationLink(destination: TaskDetailsPage(mainTask: mainTask)) {
                    TaskToDoComponent(
                        taskTitle: mainTask.title,
                        numberOfTasks: mainTask.tasks.count,
                        tasksCompleted: mainTask.tasks.filter { $0.completed }.count,
                        duration: mainTask.duration,
                        dateCompleted: mainTask.dateCompleted
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(TapGesture().onEnded {
                    var props = AnalyticsService.shared.taskProperties(mainTask)
                    props["source"] = "Completed"
                    AnalyticsService.shared.track("Task Opened", properties: props)
                })
                .taskDeleteSwipe { taskToDelete = mainTask }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.text.page")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.brandGradient)

            Text("No completed tasks yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Text("Finish a task and it'll show up here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func dateLabel(for date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let formatter = DateFormatter()
        // Drop the year for dates in the current year, keep it otherwise.
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "EEEE, MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    CompletedPage()
}
