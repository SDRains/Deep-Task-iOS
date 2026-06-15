//
//  HomeHeroComponent.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import SwiftUI

struct DashboardHeader: View {
    let dateInfo = getCurrentDate()
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared

    // Time-of-day greeting.
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var activeCount: Int {
        persistenceManager.getActiveTasks().count
    }

    private var streak: Int {
        persistenceManager.getCurrentStreak()
    }

    private var completedThisMonth: Int {
        getCompletedTasksThisMonth(from: persistenceManager.getAllTasks())
    }

    var body: some View {
        VStack(spacing: 16) {
            heroBanner

            // Stat cards
            HStack(spacing: 12) {
                StatCard(icon: "checklist", value: "\(activeCount)", label: "Active", color: .blue)
                StatCard(icon: "flame.fill", value: "\(streak)", label: "Day Streak", color: .orange)
                StatCard(icon: "trophy.fill", value: "\(completedThisMonth)", label: "This Month", color: .green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var heroBanner: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text("\(dateInfo.dayName), \(dateInfo.monthName) \(dateInfo.dateNumber)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Let's make today count!")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .orange.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// A compact statistic card: tinted icon, large rounded number, label.
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(Circle().fill(color.opacity(0.15)))

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .contentCard()
    }
}

#Preview {
    DashboardHeader()
}
