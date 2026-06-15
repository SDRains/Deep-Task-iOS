//
//  TimerComponent.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/29/25.
//

import SwiftUI

struct TimerComponent: View {
    @Environment(\.dismiss) private var dismiss

    let totalTime: TimeInterval        // in seconds (total work time)
    let initialElapsedSeconds: Int     // restored progress from a previous session
    var onPersist: (Int) -> Void       // persists the current elapsed seconds

    @State private var elapsedTime: TimeInterval
    @State private var isPaused = true
    @State private var timer: Timer?
    @State private var showPauseAlert = false
    @State private var showCancelAlert = false
    @State private var showTimeUpAlert = false
    @State private var userIsReviewingTask = false // This way when elapsedTime == totalTime, it won't continue showing the alerts
    @State private var hasLoggedCompletion = false // Ensures "Timer Completed" is logged only once per session

    init(totalTime: TimeInterval,
         initialElapsedSeconds: Int = 0,
         onPersist: @escaping (Int) -> Void = { _ in }) {
        self.totalTime = totalTime
        self.initialElapsedSeconds = initialElapsedSeconds
        self.onPersist = onPersist
        // Seed @State via its backing store (standard iOS 18+ pattern).
        self._elapsedTime = State(initialValue: TimeInterval(min(max(initialElapsedSeconds, 0), Int(totalTime))))
    }

    var remainingTime: TimeInterval {
        max(0, totalTime - elapsedTime)
    }

    var progress: Double {
        totalTime > 0 ? elapsedTime / totalTime : 0
    }

    // Whether there's a saved, partially-completed session to resume.
    private var hasSavedProgress: Bool {
        elapsedTime > 0 && remainingTime > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            let circleSize: CGFloat = 250

            // Timer Circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: circleSize, height: circleSize)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                // Timer content
                VStack(spacing: 2) {
                    Text("Elapsed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(formatTime(elapsedTime))
                        .font(.system(size: 42, weight: .light, design: .monospaced))
                        .foregroundColor(.primary)

                    Text("Remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)

                    Text(formatTime(remainingTime))
                        .font(.system(size: 32, weight: .regular, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            // Action Buttons
            HStack(spacing: 16) {
                if remainingTime == 0 {
                    // Session complete — allow starting a fresh one.
                    Button(action: {
                        AnalyticsService.shared.track("Timer Reset", properties: [
                            "previousElapsedSeconds": Int(elapsedTime)
                        ])
                        startOver()
                    }) { primaryLabel("Start Over") }
                } else if elapsedTime == 0 {
                    // Fresh, unstarted timer.
                    Button(action: {
                        AnalyticsService.shared.track("Timer Started", properties: [
                            "totalSeconds": Int(totalTime)
                        ])
                        toggleBreak()
                    }) { primaryLabel("Start Task") }
                } else if isPaused {
                    // Saved/paused session — resume where we left off or restart.
                    Button(action: {
                        AnalyticsService.shared.track("Timer Resumed", properties: [
                            "resumedFromSeconds": Int(elapsedTime)
                        ])
                        toggleBreak()
                    }) { primaryLabel("Resume") }
                    Button(action: {
                        AnalyticsService.shared.track("Timer Reset", properties: [
                            "previousElapsedSeconds": Int(elapsedTime)
                        ])
                        startOver()
                    }) { secondaryLabel("Start Over") }
                } else {
                    // Running.
                    Button(action: { toggleBreak() }) { primaryLabel("Pause") }
                    Button(action: { showCancelAlert = true }) { secondaryLabel("Cancel Task") }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
            persist()
        }
        // Pause Alert
        .alert("Stay Focused", isPresented: $showPauseAlert) {
            Button("Stay Focused", role: .none) {
                // Do nothing - keep timer running
                isPaused = false // confirm timer keeps running
            }
            Button("Pause Timer") {
                isPaused = true
                persist()
                AnalyticsService.shared.track("Timer Paused", properties: [
                    "elapsedSeconds": Int(elapsedTime),
                    "remainingSeconds": Int(remainingTime)
                ])
            }
        } message: {
            Text("Avoid breaks during your deep work session and stay in the focus zone.")
        }
        // Cancel Alert
        .alert("Are you sure?", isPresented: $showCancelAlert) {
            Button("Stay Focused", role: .none) {
                // Do nothing - keep timer running
                isPaused = false // confirm timer keeps running
            }
            Button("Cancel Task") {
                AnalyticsService.shared.track("Timer Cancelled", properties: [
                    "elapsedSeconds": Int(elapsedTime)
                ])
                isPaused = true
                elapsedTime = 0
                persist()
                dismiss()
            }
        } message: {
            Text("You have not finished the duration of your deep work session. Are you sure you want to cancel this task? The timer will reset.")
        }
        // Timer Complete Alert
        .alert("Time Complete", isPresented: $showTimeUpAlert) {
            Button("Ok", role: .none) {
                showTimeUpAlert = false
                dismiss()
            }
            Button("Review Task") {
                showTimeUpAlert = false
                userIsReviewingTask = true // Hides all alerts
            }
        } message: {
            Text("Your allocated deep work time for this task has concluded. Take a short break and then return to work to keep your productivity high.")
        }
    }

    // MARK: - Button Labels

    private func primaryLabel(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }

    private func secondaryLabel(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.primary.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
    }

    // MARK: - Helper Methods
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // Persist the current elapsed time so the session can be resumed later.
    func persist() {
        onPersist(Int(elapsedTime))
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused && elapsedTime < totalTime {
                elapsedTime += 1
            }

            if (elapsedTime == totalTime && !userIsReviewingTask) { // Timer has completed
                if !hasLoggedCompletion {
                    hasLoggedCompletion = true
                    AnalyticsService.shared.track("Timer Completed", properties: [
                        "totalSeconds": Int(totalTime)
                    ])
                }
                showTimeUpAlert = true
            }

        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func toggleBreak() {
        // If we're about to pause (currently running and has elapsed time), show alert
        if !isPaused && elapsedTime > 0 {
            showPauseAlert = true
        } else {
            // Otherwise just toggle normally (for resume or start)
            isPaused.toggle()

            if (elapsedTime == 0) {
                elapsedTime += 1 // Immediately start timer to avoid 1 sec delay
            }
        }
    }

    // Reset the session back to the beginning.
    func startOver() {
        isPaused = true
        userIsReviewingTask = false
        elapsedTime = 0
        persist()
    }
}

// MARK: - Preview
struct TaskDetailsTimer_Previews: PreviewProvider {
    static var previews: some View {
        TimerComponent(totalTime: 25 * 60, initialElapsedSeconds: 8 * 60)
    }
}
