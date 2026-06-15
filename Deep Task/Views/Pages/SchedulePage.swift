//
//  SchedulePage.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import SwiftUI

// The daily planner. Shows a vertical timeline of schedule blocks for the
// selected date and scope (General / weekday-custom / one-off).
struct SchedulePage: View {
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var selectedScope: ResolvedScope = .everyday
    @State private var showAddBlock = false
    @State private var showWeekOverview = false

    @ObservedObject private var scheduleManager = SchedulePersistenceManager.shared

    private let calendar = Calendar.current

    private var availableScopes: [ResolvedScope] {
        scheduleManager.availableScopes(on: selectedDate)
    }

    private var visibleBlocks: [ScheduleBlock] {
        scheduleManager.blocks(for: selectedScope)
    }

    private var dateLabel: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        if calendar.isDateInTomorrow(selectedDate) { return "Tomorrow" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    private var dateSubLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                dateNavigator

                // Scope selector (only meaningful when more than General is available).
                if availableScopes.count > 1 {
                    Picker("Schedule", selection: $selectedScope) {
                        ForEach(availableScopes, id: \.self) { scope in
                            Text(scope.label(for: selectedDate)).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                }

                planner
            }
            .background(Color(.systemGray6))
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showWeekOverview = true }) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddBlock = true }) {
                        Image(systemName: "plus")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddBlock) {
                AddScheduleBlockView(
                    isPresented: $showAddBlock,
                    initialScope: selectedScope,
                    viewedDate: selectedDate
                )
            }
            .sheet(isPresented: $showWeekOverview) {
                WeekAtAGlanceView { day in
                    selectedDate = day
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onAppear { reconcileScope() }
            .onChange(of: selectedDate) { _, _ in reconcileScope() }
            .onChange(of: scheduleManager.scheduleCollection.blocks.count) { _, _ in reconcileScope() }
        }
    }

    // MARK: - Subviews

    private var dateNavigator: some View {
        HStack {
            Button(action: { changeDay(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(dateLabel)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Text(dateSubLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { changeDay(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var planner: some View {
        ScrollView {
            if visibleBlocks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.day.timeline.left")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No blocks yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Tap the + button to block out time for this day.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                VStack(spacing: 10) {
                    ForEach(visibleBlocks) { block in
                        NavigationLink(destination: ScheduleBlockDetailPage(blockID: block.id)) {
                            ScheduleBlockRow(block: block)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - Helpers

    private func changeDay(by days: Int) {
        if let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = calendar.startOfDay(for: newDate)
        }
    }

    // Ensure the selected scope is valid for the current date; default to the
    // most specific available scope otherwise.
    private func reconcileScope() {
        let scopes = scheduleManager.availableScopes(on: selectedDate)
        if !scopes.contains(selectedScope) {
            selectedScope = scopes.first ?? .everyday
        }
    }
}

#Preview {
    SchedulePage()
}
