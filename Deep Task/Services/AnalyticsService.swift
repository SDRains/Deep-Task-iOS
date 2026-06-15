//
//  AnalyticsService.swift
//  Deep Task
//
//  Thin wrapper around Mixpanel so the rest of the app never touches the
//  SDK directly. Centralizes initialization and event tracking, which keeps
//  analytics easy to expand and simple to stub or swap out later.
//

import Foundation
import Mixpanel

/// Central entry point for all analytics in the app.
final class AnalyticsService {
    /// Shared instance used throughout the app.
    static let shared = AnalyticsService()

    /// Mixpanel project token (a write-only ingestion token, safe to embed).
    private let projectToken = "2ce214d577b743cee3971bde1a11b0ba"

    private init() {}

    /// Initializes Mixpanel. Must be called once, at app launch.
    func start() {
        Mixpanel.initialize(token: projectToken, trackAutomaticEvents: false)

        #if DEBUG
        // Surfaces Mixpanel's own debug output so we can confirm events are sent.
        Mixpanel.mainInstance().loggingEnabled = true
        #endif
    }

    /// Tracks an event, optionally with associated properties. Properties are
    /// accepted as `[String: Any]` so call sites never need to import Mixpanel;
    /// any value that isn't a valid Mixpanel type is simply dropped.
    func track(_ event: String, properties: [String: Any]? = nil) {
        let mixpanelProps = properties?.compactMapValues { $0 as? MixpanelType }
        Mixpanel.mainInstance().track(event: event, properties: mixpanelProps)
    }

    /// Forces queued events to be sent to Mixpanel immediately.
    /// Useful for verification; normally Mixpanel batches automatically.
    func flush() {
        Mixpanel.mainInstance().flush()
    }
}

// MARK: - Screen tracking

extension AnalyticsService {
    /// Every screen the user can land on. The raw value is sent as the
    /// `screen` property on the shared "Screen Viewed" event.
    enum Screen: String {
        case onboarding = "Onboarding"
        case home = "Home"
        case schedule = "Schedule"
        case completed = "Completed"
        case momentum = "Momentum"
        case taskDetails = "Task Details"
        case scheduleBlockDetail = "Schedule Block Detail"
        case weekAtAGlance = "Week At A Glance"
        case addTask = "Add Task"
        case addScheduleBlock = "Add Schedule Block"
        case privacy = "Privacy"
    }

    /// Fires the single "Screen Viewed" event, tagging it with the screen name
    /// and merging in any generic context properties (counts, durations — never
    /// user-entered content).
    func trackScreen(_ screen: Screen, properties: [String: Any]? = nil) {
        var merged: [String: Any] = ["screen": screen.rawValue]
        if let properties {
            for (key, value) in properties { merged[key] = value }
        }
        track("Screen Viewed", properties: merged)
    }
}

// MARK: - Task event properties

extension AnalyticsService {
    /// Builds the generic, non-personal property set describing a task.
    /// Deliberately excludes the task title and any subtask titles.
    func taskProperties(_ task: MainTask) -> [String: Any] {
        [
            "subtaskCount": task.tasks.count,
            "completedSubtaskCount": task.tasks.filter { $0.completed }.count,
            "taskDuration": task.duration,
            "isComplete": task.dateCompleted != nil,
            "isScheduleBlockTask": task.scheduleBlockID != nil
        ]
    }
}
