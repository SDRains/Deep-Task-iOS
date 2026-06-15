//
//  ToDoComponent.swift
//  Deep Task
//
//  Created by Stephen Rains on 9/2/25.
//

import SwiftUI

struct ToDoComponent: View {
    @Binding var mainTask: MainTask
    @State private var showTaskCompleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(mainTask.tasks.enumerated()), id: \.element.id) { index, taskItem in
                TodoItemRow(
                    taskIndex: index,
                    mainTask: $mainTask,
                    showTaskCompleteAlert: $showTaskCompleteAlert
                )
            }
        }
        .padding(.horizontal, 20)
        // Tasks Complete Alert
        .alert("Congrats!", isPresented: $showTaskCompleteAlert) {
            Button("Okay", role: .none) {
                showTaskCompleteAlert = false
            }
            Button("Back Home") {
                showTaskCompleteAlert = false
                dismiss()
            }
        } message: {
            Text("All your tasks have been completed! We recommend spending the remainder of your session improving your work.")
        }
    }
}

struct TodoItemRow: View {
    let taskIndex: Int
    @Binding var mainTask: MainTask
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared
    @Binding var showTaskCompleteAlert: Bool
    
    private var taskItem: TaskItem {
        mainTask.tasks[taskIndex]
    }
    
    func updateTaskStatus() {
        withAnimation(.easeInOut(duration: 0.2)) {
            // Update the task directly in the binding
            mainTask.tasks[taskIndex].completed.toggle()
            
            // Debounce the save operation to avoid rapid successive saves
            persistenceManager.debouncedUpdateTask(mainTask)
            
            // Check if all tasks are complete
            if (isMainTaskComplete(mainTask: mainTask)) {
                showTaskCompleteAlert = true
                mainTask.dateCompleted = Date()
                persistenceManager.updateTask(mainTask)
            } else { // Ensures dateCompleted is nil if not all tasks completed
                mainTask.dateCompleted = nil
                persistenceManager.updateTask(mainTask)
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(taskItem.title)
                .font(.system(size: 17))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Custom checkbox
            Button(action: updateTaskStatus) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(taskItem.completed ? Color.black : Color.gray.opacity(0.3), lineWidth: taskItem.completed ? 0 : 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(taskItem.completed ? Color.black : Color.clear)
                        )
                        .frame(width: 24, height: 24)
                    
                    if taskItem.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Preview
struct TaskDetailsToDoView_Previews: PreviewProvider {
    @State static var demoTask = demoTaskData()
    
    static var previews: some View {
        ToDoComponent(mainTask: $demoTask)
            .previewLayout(.sizeThatFits)
    }
}
