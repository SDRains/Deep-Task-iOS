//
//  HomePage.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/27/25.
//

import SwiftUI

struct HomePage: View {
    @State private var showAddTask = false
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared
    @State private var taskToDelete: MainTask?
    //@State private var selectedTab: TabType = .tasks

    enum TabType {
        case tasks, calendar
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DashboardHeader()

                    // Toggle buttons using Picker
//                    Picker("Tab Selection", selection: $selectedTab) {
//                        Text("Tasks").tag(TabType.tasks)
//                        Text("Focus Chain").tag(TabType.calendar)
//                    }
//                    .pickerStyle(.segmented)
//                    .padding(.horizontal, 20)

//                    if selectedTab == .tasks {
//                        tasksContent
//                    } else {
//                        FocusChainComponent()
//                    }
                    
                    tasksContent

                    Spacer(minLength: 40)
                }
            }
            .taskSwipeContainer()
            .confirmTaskDeletion($taskToDelete) { task in
                persistenceManager.deleteTask(withId: task.id)
            }
            //.background(AppTheme.backgroundGradient.ignoresSafeArea())
            .background(Color(.systemGray6))
            .navigationTitle("Deep Task")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showAddTask = true
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView(isPresented: $showAddTask)
            }
        }
    }

    // MARK: - Tasks content

    @ViewBuilder
    private var tasksContent: some View {
        if persistenceManager.getActiveTasks().isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Tasks")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)

                ForEach(persistenceManager.getActiveTasks()) { mainTask in
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
                    .taskDeleteSwipe { taskToDelete = mainTask }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.brandGradient)

            Text("No tasks yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Text("Tap the + button to create your first task")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showAddTask = true }) {
                Label("New Task", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.brandGradient)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .padding(.horizontal, 20)
    }
}

#Preview {
    HomePage()
}
