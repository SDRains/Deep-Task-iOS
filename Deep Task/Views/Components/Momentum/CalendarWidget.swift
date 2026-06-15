//
//  CalendarView.swift
//  Deep Task
//
//  Created by Stephen Rains on 9/5/25.
//

import SwiftUI

struct CalendarWidget: View {
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Top message about completed sessions
            VStack(alignment: .leading) {
                if getNumCompletedTasksThisMonth() > 0 {
                    Text("Keep it going! You've completed \(getNumCompletedTasksThisMonth()) day of deep work this month!")
                        .font(.title3)
                        .foregroundColor(.gray)
                } else {
                    Text("Get started by completing one day of deep work this month!")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
            }
            .padding(.top, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Calendar grid
            VStack(spacing: 12) {
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                    ForEach(getDaysInMonth(), id: \.self) { date in
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            isToday: calendar.isDateInToday(date),
                            isFutureDate: date > Date(),
                            hasCompletedTasks: persistenceManager.getTasksCompletedOn(date: date).count > 0
                        )
                        .onTapGesture {
                            selectedDate = date
                            AnalyticsService.shared.track("Calendar Date Selected", properties: [
                                "hasCompletedTasks": persistenceManager.getTasksCompletedOn(date: date).count > 0,
                                "isFutureDate": date > Date()
                            ])
                        }
                    }
                }
                
                // Legend/Key
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.green)
                            .frame(width: 16, height: 16)
                        Text("Day with a completed deep work session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        Circle()
                            .strokeBorder(Color(.systemGray3), lineWidth: 2)
                            .frame(width: 16, height: 16)
                        Text("Day without a deep work session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 16, height: 16)
                        Text("Today's date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.top, 16)
            }
            
            Spacer()
        }
    }
    
    private func getDaysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1)
        else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private func getNumCompletedTasksThisMonth() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth
        
        return persistenceManager.getCompletedTasks().filter { task in
            guard let completedDate = task.dateCompleted else { return false }
            return completedDate >= startOfMonth && completedDate < endOfMonth
        }.count
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let isFutureDate: Bool
    let hasCompletedTasks: Bool
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: 32, height: 32)
            .overlay(
                Circle()
                    .strokeBorder(strokeColor, lineWidth: 1.5)
            )
            .overlay(
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
            )
    }

    // Past day in the current month with no completed session: drawn as an
    // outlined circle rather than a solid fill (see strokeColor / textColor).
    private var isMissedDay: Bool {
        isCurrentMonth && !isToday && !isFutureDate && !hasCompletedTasks
    }

    private var backgroundColor: Color {
        if isToday {
            return .orange
        } else if isFutureDate && isCurrentMonth {
            return Color(.systemGray5)
        } else if hasCompletedTasks && isCurrentMonth {
            return .green
        } else {
            // Missed days (outlined) and other-month days have no solid fill.
            return .clear
        }
    }

    private var strokeColor: Color {
        isMissedDay ? Color(.systemGray3) : .clear
    }

    private var textColor: Color {
        if isToday {
            return .white
        } else if hasCompletedTasks && isCurrentMonth {
            return .white
        } else if isMissedDay {
            // Adaptive: dark in light mode, light in dark mode — always legible.
            return .primary
        } else if isFutureDate && isCurrentMonth {
            return .secondary
        } else {
            return .clear
        }
    }
}

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWidget()
    }
}
