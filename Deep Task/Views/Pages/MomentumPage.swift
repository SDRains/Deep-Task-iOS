//
//  MomentumPage.swift
//  Deep Task
//
//  Created by Stephen Rains on 9/5/25.
//

import SwiftUI

struct MomentumPage: View {
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView {
                    CalendarWidget()
//                    if persistenceManager.getCompletedTasks().isEmpty {
//                        // Show placeholder if no tasks
//                        VStack(spacing: 16) {
//                            Image(systemName: "chart.line.uptrend.xyaxis")
//                                .font(.system(size: 48))
//                                .foregroundStyle(AppTheme.brandGradient)
//                            
//                            Text("No Completed Tasks")
//                                .font(.headline)
//                                .foregroundColor(.gray)
//                            
//                            Text("Complete a task to start seeing your focus momentum!")
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                                .multilineTextAlignment(.center)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 48)
//                    } else {
//                        CalendarWidget()
//                    }
                }
            }
            .padding(.horizontal)
            .background (Color(.systemGray6))
            .navigationTitle("Momentum")
            .onAppear {
                AnalyticsService.shared.trackScreen(.momentum, properties: [
                    "completedTaskCount": persistenceManager.getCompletedTasks().count
                ])
            }
        }
    }
}

#Preview {
    MomentumPage()
}
