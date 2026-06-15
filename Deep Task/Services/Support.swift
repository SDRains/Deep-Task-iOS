//
//  Support.swift
//  Deep Task
//
//  Created by Stephen Rains on 9/5/25.
//

import Foundation

// MARK: - Collection of Supporting Functions for App
func isMainTaskComplete(mainTask: MainTask) -> Bool {
    for subTask in mainTask.tasks {
        if (!subTask.completed) {
            return false
        }
    }
    
    return true
}

func formatDateToLocalString(_ date: Date) -> String {
    let formatter = DateFormatter()
    
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "MMM d, yyyy '@' h:mma"
    
    return formatter.string(from: date)
}

struct TaskCompletionStats {
    let completedToday: Int
    let completedYesterday: Int
    let completedThisMonth: Int
}

// MARK: - Global Task Statistics Functions

/**
 Returns the number of completed tasks for a given month
 - Parameter tasks: Array of MainTask objects to analyze
 - Parameter month: The month to analyze (defaults to current date)
 - Returns: Count of tasks completed in the specified month
 */
func getCompletedTasksThisMonth(from tasks: [MainTask], for month: Date = Date()) -> Int {
    let calendar = Calendar.current
    let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
    let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
    
    return tasks.filter { task in
        guard let completedDate = task.dateCompleted else { return false }
        return completedDate >= startOfMonth && completedDate < endOfMonth
    }.count
}

/**
 Returns tasks completed on a specific date
 - Parameter date: The specific date to check
 - Parameter tasks: Array of MainTask objects to analyze
 - Returns: Array of MainTask objects completed on the specified date
 */
func getTasksCompletedOn(date: Date, from tasks: [MainTask]) -> [MainTask] {
    let calendar = Calendar.current
    return tasks.filter { task in
        guard let completedDate = task.dateCompleted else { return false }
        return calendar.isDate(completedDate, inSameDayAs: date)
    }
}

/**
 Returns comprehensive task completion statistics
 - Parameter tasks: Array of MainTask objects to analyze
 - Parameter month: The month to use for "this month" calculation (defaults to current date)
 - Returns: TaskCompletionStats object with today, yesterday, and monthly counts
 */
func getTaskCompletionStats(from tasks: [MainTask], for month: Date = Date()) -> TaskCompletionStats {
    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
    
    // Tasks completed today
    let completedToday = getTasksCompletedOn(date: today, from: tasks).count
    
    // Tasks completed yesterday
    let completedYesterday = getTasksCompletedOn(date: yesterday, from: tasks).count
    
    // Tasks completed this month
    let completedThisMonth = getCompletedTasksThisMonth(from: tasks, for: month)
    
    return TaskCompletionStats(
        completedToday: completedToday,
        completedYesterday: completedYesterday,
        completedThisMonth: completedThisMonth
    )
}
