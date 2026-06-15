//
//  TaskDeleteSwipe.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/11/26.
//

import SwiftUI

// Shared swipe-to-delete behavior for task rows. Provides the standard iOS
// trailing (right-to-left) destructive swipe plus a confirmation step so a
// task is never deleted without the user confirming.
//
// Usage:
//   ScrollView { ... rows ... }
//       .taskSwipeContainer()                          // enables swipe outside a List (iOS 27+)
//       .confirmTaskDeletion($taskToDelete) { task in  // page-level confirmation
//           persistenceManager.deleteTask(withId: task.id)
//       }
//
//   // on each row:
//   row.taskDeleteSwipe { taskToDelete = mainTask }
extension View {
    // Enables swipe actions for rows inside a scrollable container (not a List).
    // `swipeActionsContainer()` is iOS 27+, so it's gated; on older systems the
    // swipe simply isn't offered.
    @ViewBuilder
    func taskSwipeContainer() -> some View {
//        if #available(iOS 27.0, *) {
//            self.swipeActionsContainer()
//        } else {
//            self
//        }
        self
    }

    // Adds a trailing destructive "Delete" swipe action to a task row.
    // The `swipeActions` row modifier is iOS 15+; it only takes effect inside a
    // List or a `taskSwipeContainer()` (iOS 27+).
    func taskDeleteSwipe(_ action: @escaping () -> Void) -> some View {
        self.swipeActions(edge: .trailing) {
            Button(role: .destructive, action: action) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // Presents a confirmation alert before deleting the bound task.
    func confirmTaskDeletion(
        _ task: Binding<MainTask?>,
        onConfirm: @escaping (MainTask) -> Void
    ) -> some View {
        self.alert(
            "Delete this task?",
            isPresented: Binding(
                get: { task.wrappedValue != nil },
                set: { if !$0 { task.wrappedValue = nil } }
            ),
            presenting: task.wrappedValue
        ) { pendingTask in
            Button("Delete Task", role: .destructive) {
                onConfirm(pendingTask)
                task.wrappedValue = nil
            }
            Button("Cancel", role: .cancel) {
                task.wrappedValue = nil
            }
        } message: { pendingTask in
            Text("\"\(pendingTask.title)\" and all of its steps will be permanently deleted. This can't be undone.")
        }
    }
}
