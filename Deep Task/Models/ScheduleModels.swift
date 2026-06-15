//
//  ScheduleModels.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import Foundation

// MARK: - Schedule Scope

// Describes how a schedule block recurs / which days it applies to.
enum ScheduleScopeType: String, Codable {
    case everyday   // The general schedule, shown every day by default
    case weekday    // Recurring on specific weekday(s), e.g. every Tuesday
    case oneOff     // A single specific calendar date, e.g. a travel day
}

// A resolved scope for a particular day, used by the planner's scope selector.
// Scopes are mutually exclusive: a day shows exactly one scope's blocks at a time.
enum ResolvedScope: Hashable {
    case everyday
    case weekday(Int)   // Calendar weekday 1...7 (Sun...Sat)
    case oneOff(Date)   // Start-of-day date

    var type: ScheduleScopeType {
        switch self {
        case .everyday: return .everyday
        case .weekday: return .weekday
        case .oneOff: return .oneOff
        }
    }

    // Short label for the segmented selector.
    func label(for date: Date) -> String {
        switch self {
        case .everyday:
            return "General"
        case .weekday:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Full weekday name
            return formatter.string(from: date)
        case .oneOff:
            return "This Day"
        }
    }
}

// MARK: - Schedule Block

// A single time-blocked item in a schedule (e.g. "Company 1 Work" 9:00 AM - 5:00 PM).
struct ScheduleBlock: Codable, Identifiable {
    var id = UUID()
    var title: String
    var startMinutes: Int            // Minutes from midnight, multiple of 15 (0...1440)
    var endMinutes: Int              // Multiple of 15, must be > startMinutes
    var scopeType: ScheduleScopeType
    var weekdays: [Int]?             // Calendar weekdays 1...7 (Sun...Sat) when .weekday
    var date: Date?                  // Start-of-day date when .oneOff

    init(title: String,
         startMinutes: Int,
         endMinutes: Int,
         scopeType: ScheduleScopeType,
         weekdays: [Int]? = nil,
         date: Date? = nil) {
        self.title = title
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.scopeType = scopeType
        self.weekdays = weekdays
        self.date = date
    }

    // Duration of the block in minutes.
    var durationMinutes: Int {
        max(0, endMinutes - startMinutes)
    }

    // Whether this block belongs to the given resolved scope grouping.
    func belongs(to scope: ResolvedScope) -> Bool {
        switch scope {
        case .everyday:
            return scopeType == .everyday
        case .weekday(let weekday):
            return scopeType == .weekday && (weekdays?.contains(weekday) ?? false)
        case .oneOff(let day):
            guard scopeType == .oneOff, let date = date else { return false }
            return Calendar.current.isDate(date, inSameDayAs: day)
        }
    }

    // Two blocks overlap if their time ranges intersect.
    func overlaps(_ other: ScheduleBlock) -> Bool {
        startMinutes < other.endMinutes && endMinutes > other.startMinutes
    }
}

// MARK: - Schedule Collection

struct ScheduleCollection: Codable {
    var blocks: [ScheduleBlock]

    init() {
        self.blocks = []
    }
}

// MARK: - Time Formatting Helpers

// Formats minutes-from-midnight into a clock string, e.g. 525 -> "8:45 AM".
func formatMinutesAsTime(_ minutes: Int) -> String {
    let clamped = min(max(minutes, 0), 24 * 60)
    let hour24 = (clamped / 60) % 24
    let minute = clamped % 60

    let period = hour24 < 12 ? "AM" : "PM"
    var hour12 = hour24 % 12
    if hour12 == 0 { hour12 = 12 }

    return String(format: "%d:%02d %@", hour12, minute, period)
}

// Formats a block duration in minutes into a readable string, e.g. 105 -> "1h 45m".
func formatDurationMinutes(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60

    if hours > 0 && mins > 0 {
        return "\(hours)h \(mins)m"
    } else if hours > 0 {
        return "\(hours)h"
    } else {
        return "\(mins)m"
    }
}

// The 15-minute time slots in a day as minutes-from-midnight (0, 15, ... 1440).
let dailyTimeSlots: [Int] = Array(stride(from: 0, through: 24 * 60, by: 15))
