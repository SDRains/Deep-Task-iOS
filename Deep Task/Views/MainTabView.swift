//
//  MainTabView.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomePage()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            SchedulePage()
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Schedule")
                }

            CompletedPage()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Completed")
                }
            
            MomentumPage()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Momentum")
                }
        }
        .tint(AppTheme.accent)
    }
}

// MARK: - Preview
struct MainTabViewPreviews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
