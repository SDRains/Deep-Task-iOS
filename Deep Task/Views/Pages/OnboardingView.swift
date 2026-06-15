//
//  OnboardingView.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import SwiftUI

// First-launch onboarding that explains the concept of the app and why
// focused, deliberate work matters. The "Get Started" button calls
// `onGetStarted`, which the parent uses to persist that onboarding is done.
struct OnboardingView: View {
    var onGetStarted: () -> Void
    @State private var showPrivacy = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    hero

                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "target",
                            tint: .indigo,
                            title: "Break big goals down",
                            description: "Turn an overwhelming task into small, concrete steps you can actually finish — and check off one at a time."
                        )
                        FeatureRow(
                            icon: "timer",
                            tint: .red,
                            title: "Work in focused sprints",
                            description: "Give each task a time box and a countdown. A clear finish line keeps you in deep, distraction-free work."
                        )
                        FeatureRow(
                            icon: "flame.fill",
                            tint: .orange,
                            title: "Build unstoppable momentum",
                            description: "Complete sessions to grow your focus streak. Small wins compound into real, lasting progress."
                        )
                    }

                    // Why it matters
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Why it matters")
//                            .font(.system(size: 15, weight: .semibold))
//                            .foregroundColor(.secondary)
//
//                        Text("Focus is your most valuable resource. Constant switching and vague to-do lists drain it fast. Deep Task helps you do one meaningful thing at a time — so you make steady progress toward what actually matters, without burning out.")
//                            .font(.system(size: 15))
//                            .foregroundColor(.primary)
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }

            // Pinned call-to-action
            VStack(spacing: 8) {
                getStartedButton
                privacyLink
            }
        }
        .background(Color(.systemGray6))
        //.background(AppTheme.backgroundGradient.ignoresSafeArea())
        .onAppear { AnalyticsService.shared.trackScreen(.onboarding) }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Subviews

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack {
                Image("v3_deep_task_icon")
    //                .font(.system(size: 34, weight: .bold))
    //                .foregroundStyle(.white)
                    .resizable()         // Allows the image to scale
                    .scaledToFit()       // Maintains aspect ratio without stretching
                    .frame(width: 72, height: 72)
                    //.background(AppTheme.brandGradient)
                    .padding(2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to\nDeep Task")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("A calmer way to get meaningful work done — one focused task at a time.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var getStartedButton: some View {
        Button(action: {
            AnalyticsService.shared.track("Onboarding Completed")
            onGetStarted()
        }) {
            Text("Get Started")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.brandGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        //.background(.ultraThinMaterial)
    }

    private var privacyLink: some View {
        Button {
            showPrivacy = true
        } label: {
            Text("How we handle your privacy")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .underline()
        }
        .padding(.bottom, 12)
    }
}

// A single onboarding feature: tinted icon + title + description.
private struct FeatureRow: View {
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
    OnboardingView(onGetStarted: {})
}
