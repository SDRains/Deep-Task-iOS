//
//  TaskModels.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import Foundation

// Individual task item within a main task
struct TaskItem: Codable, Identifiable {
    var id = UUID()
    var completed: Bool
    var title: String
    
    init(title: String, completed: Bool = false) {
        self.title = title
        self.completed = completed
    }
}

// Main task object
struct MainTask: Codable, Identifiable {
    var id = UUID()
    let title: String
    var tasks: [TaskItem]
    let duration: Int // Duration in minutes
    let dateCreated: Date
    var dateCompleted: Date? // Set when all tasks are completed, nil when incomplete
    var scheduleBlockID: UUID? // Set when this task belongs to a schedule block, nil for standalone Home tasks
    var elapsedSeconds: Int? // Persisted timer progress so a paused session can be resumed later. nil/0 means not started.

    init(title: String, tasks: [TaskItem], duration: Int, scheduleBlockID: UUID? = nil) {
        self.title = title
        self.tasks = tasks
        self.duration = duration
        self.dateCreated = Date()
        self.dateCompleted = nil
        self.scheduleBlockID = scheduleBlockID
    }
    
    // Computed property to check if all tasks are completed
    var isComplete: Bool {
        return !tasks.isEmpty && tasks.allSatisfy { $0.completed }
    }
    
    // Computed property for completion percentage
    var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completedCount = tasks.filter { $0.completed }.count
        return Double(completedCount) / Double(tasks.count)
    }
    
    // Computed property for completed task count
    var completedTasksCount: Int {
        return tasks.filter { $0.completed }.count
    }
}

func demoTaskData() -> MainTask {
    return MainTask(title: "Sample Task", tasks: [
        TaskItem(title: "Sample Task 1", completed: false),
        TaskItem(title: "Sample Task 2", completed: false),
        TaskItem(title: "Sample Task 3", completed: false),
        TaskItem(title: "Sample Task 4", completed: false),
    ], duration: 1)
}

// Collection of all tasks
struct TaskCollection: Codable {
    var tasks: [MainTask]
    
    init() {
        self.tasks = []
    }
}
