//
//  DateHandlers.swift
//  Deep Task
//
//  Created by Stephen Rains on 9/2/25.
//

import Foundation

struct DateInfo {
    let monthName: String
    let dateNumber: Int
    let dayName: String
}

func getCurrentDate() -> DateInfo {
    let currentDate = Date()
    let calendar = Calendar.current
    
    // Get date number
    let dateNumber = calendar.component(.day, from: currentDate)
    
    // Create formatters for month and day names
    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMM" // Short month name (Jan, Feb, etc.)
    
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE" // Full day name (Monday, Tuesday, etc.)
    
    // Get formatted strings
    let monthName = monthFormatter.string(from: currentDate)
    let dayName = dayFormatter.string(from: currentDate)
    
    return DateInfo(
        monthName: monthName,
        dateNumber: dateNumber,
        dayName: dayName
    )
}

// Example usage:
//let dateInfo = getCurrentDate()
//print("Month: \(dateInfo.monthName)")
//print("Date: \(dateInfo.dateNumber)")
//print("Day: \(dateInfo.dayName)")

func currentDateString() -> String {
    let dateInfo = getCurrentDate()
    return "\(dateInfo.monthName) \(dateInfo.dateNumber), \(dateInfo.dayName)"
}

// For SwiftUI usage, you might also want a computed property version:
extension Date {
    var dateInfo: DateInfo {
        let calendar = Calendar.current
        let dateNumber = calendar.component(.day, from: self)
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        return DateInfo(
            monthName: monthFormatter.string(from: self),
            dateNumber: dateNumber,
            dayName: dayFormatter.string(from: self)
        )
    }
}
