//
//  ContentView.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/27/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    // Persisted across launches. Onboarding only shows until the user taps
    // "Get Started" once, which flips this flag permanently.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    withAnimation(.easeInOut) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
