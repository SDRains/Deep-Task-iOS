//
//  ScheduleBlockDetailPage.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import SwiftUI

// Shows a single schedule block and the deep-work tasks scheduled inside it.
// Tasks reuse the existing TaskDetailsPage / timer / subtask flow.
struct ScheduleBlockDetailPage: View {
    @Environment(\.dismiss) private var dismiss
    let blockID: UUID

    @State private var showAddTask = false
    @State private var showEditBlock = false
    @State private var showDeleteAlert = false
    @State private var taskToDelete: MainTask?

    @ObservedObject private var scheduleManager = SchedulePersistenceManager.shared
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared

    // The latest version of this block from the store (nil if it was deleted).
    private var block: ScheduleBlock? {
        scheduleManager.scheduleCollection.blocks.first { $0.id == blockID }
    }

    private var blockTasks: [MainTask] {
        persistenceManager.getTasks(forBlock: blockID)
    }

    var body: some View {
        Group {
            if let block = block {
                content(for: block)
            } else {
                // Block was deleted — nothing to show.
                Color(.systemGray6)
            }
        }
        .background(Color(.systemGray6))
    }

    private func content(for block: ScheduleBlock) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(formatMinutesAsTime(block.startMinutes)) – \(formatMinutesAsTime(block.endMinutes))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(block.title)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tasks
                if blockTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "timer")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No tasks in this block")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap the + button to add a focused task with a timer and subtasks.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(blockTasks) { mainTask in
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
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .taskSwipeContainer()
        .confirmTaskDeletion($taskToDelete) { task in
            persistenceManager.deleteTask(withId: task.id)
        }
        .navigationTitle("Block")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Add Task") { showAddTask = true }
                    Button("Edit Block") { showEditBlock = true }
                    Button("Delete Block", role: .destructive) { showDeleteAlert = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView(isPresented: $showAddTask, scheduleBlockID: blockID)
        }
        .sheet(isPresented: $showEditBlock) {
            AddScheduleBlockView(isPresented: $showEditBlock, editingBlock: block)
        }
        .alert("Delete this block?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                scheduleManager.deleteBlock(withId: blockID)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Deleting this block also removes any tasks scheduled inside it.")
        }
    }
}
