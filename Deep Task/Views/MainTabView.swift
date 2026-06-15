//
//  MainTabView.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    // Tab display names, indexed to match each tab's `.tag`.
    private let tabNames = ["Home", "Schedule", "Completed", "Momentum"]

    var body: some View {
        TabView(selection: $selectedTab) {
            HomePage()
                .tag(0)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            SchedulePage()
                .tag(1)
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Schedule")
                }

            CompletedPage()
                .tag(2)
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Completed")
                }

            MomentumPage()
                .tag(3)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Momentum")
                }
        }
        .tint(AppTheme.accent)
        .onChange(of: selectedTab) { _, newValue in
            let name = tabNames.indices.contains(newValue) ? tabNames[newValue] : "Unknown"
            AnalyticsService.shared.track("Tab Selected", properties: ["tab": name])
        }
    }
}

// MARK: - Preview
struct MainTabViewPreviews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
