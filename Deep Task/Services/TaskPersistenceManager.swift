//
//  TaskPersistenceManager.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import Foundation
import Combine

class TaskPersistenceManager: ObservableObject {
    static let shared = TaskPersistenceManager()
    
    @Published var taskCollection = TaskCollection()
    
    private let fileName = "tasks.json"
    private var debounceTimer: Timer?
    private var pendingUpdates: Set<UUID> = []
    
    private init() {
        loadTasks()
    }
    
    // Get the file URL for saving tasks
    private func getFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }
    
    // Save tasks to local storage
    func saveTasks() {
        do {
            let data = try JSONEncoder().encode(taskCollection)
            try data.write(to: getFileURL())
            print("Tasks saved successfully to: \(getFileURL().path)")
        } catch {
            print("Failed to save tasks: \(error.localizedDescription)")
        }
    }
    
    // Load tasks from local storage
    func loadTasks() {
        let fileURL = getFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Tasks file doesn't exist yet")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            taskCollection = try JSONDecoder().decode(TaskCollection.self, from: data)
            print("Tasks loaded successfully")
        } catch {
            print("Failed to load tasks: \(error.localizedDescription)")
            // If loading fails, start with empty collection
            taskCollection = TaskCollection()
        }
    }
    
    // Add a new main task
    func addTask(_ mainTask: MainTask) {
        taskCollection.tasks.append(mainTask)
        saveTasks()
    }
    
    // Update an existing task immediately
    func updateTask(_ updatedTask: MainTask) {
        if let index = taskCollection.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            taskCollection.tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    // Debounced update for rapid successive changes
    func debouncedUpdateTask(_ updatedTask: MainTask) {
        // Add this task to pending updates
        pendingUpdates.insert(updatedTask.id)
        
        // Update the task in memory immediately
        if let index = taskCollection.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            taskCollection.tasks[index] = updatedTask
        }
        
        // Cancel existing timer
        debounceTimer?.invalidate()
        
        // Start new timer
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.savePendingUpdates()
        }
    }
    
    private func savePendingUpdates() {
        guard !pendingUpdates.isEmpty else { return }
        
        saveTasks()
        pendingUpdates.removeAll()
        print("Saved \(pendingUpdates.count) pending task updates")
    }
    
    // Delete a task
    func deleteTask(withId id: UUID) {
        taskCollection.tasks.removeAll { $0.id == id }
        saveTasks()
    }
    
    // Get all tasks
    func getAllTasks() -> [MainTask] {
        return taskCollection.tasks
    }
    
    // Get tasks that are NOT complete (have at least one incomplete sub-task).
    // Excludes tasks that belong to a schedule block so the Home list stays uncluttered.
    func getActiveTasks() -> [MainTask] {
        return taskCollection.tasks.filter { !$0.isComplete && $0.scheduleBlockID == nil }
    }

    // Get all tasks (active or complete) belonging to a specific schedule block.
    func getTasks(forBlock blockID: UUID) -> [MainTask] {
        return taskCollection.tasks.filter { $0.scheduleBlockID == blockID }
    }

    // Delete all tasks belonging to a specific schedule block (used when a block is deleted).
    func deleteTasks(forBlock blockID: UUID) {
        taskCollection.tasks.removeAll { $0.scheduleBlockID == blockID }
        saveTasks()
    }
    
    // Get tasks that ARE complete (all sub-tasks are completed)
    func getCompletedTasks() -> [MainTask] {
        return taskCollection.tasks.filter { $0.isComplete }
    }
    
    // Get tasks completed on a specific date
    func getTasksCompletedOn(date: Date) -> [MainTask] {
        let calendar = Calendar.current
        return getCompletedTasks().filter { task in
            guard let completedDate = task.dateCompleted else { return false }
            return calendar.isDate(completedDate, inSameDayAs: date)
        }
    }
    
    // Get current streak of consecutive days with at least one completed task
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        var currentDate = today
        var streakCount = 0
        
        // Check if there's a completed task today, if not, start from yesterday
        let tasksToday = getTasksCompletedOn(date: today)
        if tasksToday.isEmpty {
            currentDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        
        // Count backwards from current date
        while true {
            let tasksOnDate = getTasksCompletedOn(date: currentDate)
            if tasksOnDate.isEmpty {
                break
            }
            streakCount += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return streakCount
    }
    
    deinit {
        debounceTimer?.invalidate()
    }
}
