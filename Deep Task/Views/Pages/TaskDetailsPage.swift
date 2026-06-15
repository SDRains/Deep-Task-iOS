//
//  TaskDetailsPage.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import SwiftUI
import UIKit

struct TaskDetailsPage: View {
    @Environment(\.dismiss) private var dismiss
    @State var mainTask: MainTask
    @State private var showDeleteMainTaskAlert = false
    @State private var showAddNewTaskAlert = false
    @State private var newSubtaskText = ""
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared
    
    // Computed property for completed tasks count
    private var completedTasksCount: Int {
        mainTask.tasks.filter { $0.completed }.count
    }
    
    private var totalTasksCount: Int {
        mainTask.tasks.count
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(completedTasksCount)/\(totalTasksCount) TASKS COMPLETED")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        Text("\(mainTask.title)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ToDoComponent(mainTask: $mainTask)
                }
                TimerComponent(
                    totalTime: TimeInterval(mainTask.duration * 60),
                    initialElapsedSeconds: mainTask.elapsedSeconds ?? 0,
                    onPersist: { seconds in
                        mainTask.elapsedSeconds = seconds
                        persistenceManager.updateTask(mainTask)
                    }
                )
            }
            .background(Color(.systemGray6))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add New Subtask") {
                            showAddNewTaskAlert = true
                        }
                        
                        Button("Delete Task") {
                            showDeleteMainTaskAlert = true
                        }
                        .foregroundStyle(.red)
                        
                        Divider()
                        
                        Button("Go Back Home") {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            // Add New Task Alert
            .alert("Add New Subtask", isPresented: $showAddNewTaskAlert) {
                TextField("Enter subtask name", text: $newSubtaskText)
                    .textInputAutocapitalization(.sentences)
                
                Button("Cancel", role: .cancel) {
                    showAddNewTaskAlert = false
                    newSubtaskText = "" // Clear the text field
                }
                
                Button("Add", role: .none) {
                    mainTask.tasks.append(TaskItem(title: newSubtaskText, completed: false))
                    persistenceManager.updateTask(mainTask)
                    showAddNewTaskAlert = false
                    newSubtaskText = "" // Clear the text field after adding
                }
            } message: {
                Text("Enter a name for your new subtask.")
            }
            // Delete Task Alert
            .alert("Are you sure?", isPresented: $showDeleteMainTaskAlert) {
                Button("Delete", role: .destructive) {
                    showDeleteMainTaskAlert = false
                    persistenceManager.deleteTask(withId: mainTask.id)
                    dismiss()
                }
            } message: {
                Text("Deleting this task is irreversible and will erase all subtasks.")
            }
            .onAppear {
                // Disable the idle timer when the view appears
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                // Re-enable the idle timer when the view disappears
                // This is important to conserve battery life and allow the device to lock normally
                // when the user is no longer actively using this specific view.
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
}

#Preview {
    TaskDetailsPage(mainTask: demoTaskData())
}
