//
//  PrivacyPolicyView.swift
//  Deep Task
//
//  A plain-language explanation of how Deep Task uses analytics. Presented as
//  a sheet from onboarding and from the Home toolbar.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero

                    VStack(spacing: 16) {
                        PolicyRow(
                            icon: "person.fill.questionmark",
                            tint: .indigo,
                            title: "Completely anonymous",
                            description: "Deep Task uses a tool called Mixpanel to understand how the app is used. You don't create an account, and we never collect your name, email, or any personal identifier. Activity is tied only to a random, device-generated ID."
                        )
                        PolicyRow(
                            icon: "lock.fill",
                            tint: .green,
                            title: "Your content stays yours",
                            description: "The things you actually type — your goals, tasks, subtasks, and schedule block names — are never sent anywhere. We only record generic signals like how many tasks you create or how long a focus session lasts."
                        )
                        PolicyRow(
                            icon: "wand.and.stars",
                            tint: .orange,
                            title: "Used only to improve the app",
                            description: "This information is used for one purpose: to see which features are helpful so we can make Deep Task better. It is never used for advertising."
                        )
                        PolicyRow(
                            icon: "hand.raised.fill",
                            tint: .red,
                            title: "Never sold or shared",
                            description: "Your data is never sold. It stays inside our own private Mixpanel account and is never transmitted to any third party."
                        )
                    }

                    Text("Last updated June 15, 2026")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGray6))
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { AnalyticsService.shared.trackScreen(.privacy) }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppTheme.brandGradient)

            Text("Your privacy")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text("We measure how Deep Task is used so we can keep improving it — without ever knowing who you are or what you're working on.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// A single privacy point: tinted icon + title + description, in a content card.
private struct PolicyRow: View {
    let icon: String
    let tint: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(Circle().fill(tint.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .contentCard()
    }
}

#Preview {
    PrivacyPolicyView()
}
