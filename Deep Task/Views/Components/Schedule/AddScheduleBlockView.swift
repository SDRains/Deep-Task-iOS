//
//  AddScheduleBlockView.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import SwiftUI

// Create or edit a schedule block. The no-overlap rule is enforced within the
// block's own scope grouping on save.
struct AddScheduleBlockView: View {
    @Binding var isPresented: Bool
    private let editingBlock: ScheduleBlock?

    @State private var title: String
    @State private var scopeType: ScheduleScopeType
    @State private var selectedWeekdays: Set<Int>
    @State private var oneOffDate: Date
    @State private var startMinutes: Int
    @State private var endMinutes: Int
    @State private var showOverlapAlert: Bool

    @ObservedObject private var scheduleManager = SchedulePersistenceManager.shared

    // Calendar weekday symbols indexed 1...7 (Sun...Sat).
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    init(isPresented: Binding<Bool>,
         editingBlock: ScheduleBlock? = nil,
         initialScope: ResolvedScope = .everyday,
         viewedDate: Date = Date()) {
        // Assign non-@State stored properties first.
        self._isPresented = isPresented
        self.editingBlock = editingBlock

        let calendar = Calendar.current
        let viewedWeekday = calendar.component(.weekday, from: viewedDate)

        // Then assign @State properties (SDK 27 @State macro: direct assignment, no initial value).
        if let block = editingBlock {
            self.title = block.title
            self.scopeType = block.scopeType
            self.selectedWeekdays = Set(block.weekdays ?? [viewedWeekday])
            self.oneOffDate = block.date ?? viewedDate
            self.startMinutes = block.startMinutes
            self.endMinutes = block.endMinutes
        } else {
            self.title = ""
            self.scopeType = initialScope.type
            switch initialScope {
            case .weekday(let weekday):
                self.selectedWeekdays = [weekday]
            default:
                self.selectedWeekdays = [viewedWeekday]
            }
            if case .oneOff(let date) = initialScope {
                self.oneOffDate = date
            } else {
                self.oneOffDate = viewedDate
            }
            self.startMinutes = 9 * 60   // 9:00 AM
            self.endMinutes = 10 * 60    // 10:00 AM
        }
        self.showOverlapAlert = false
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        endMinutes > startMinutes &&
        (scopeType != .weekday || !selectedWeekdays.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        FloatingLabelTextField(placeholder: "Title", text: $title)
                    }
                    .padding(.top, 24)

                    // Recurrence scope
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Repeats")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Picker("Repeats", selection: $scopeType) {
                            Text("Every Day").tag(ScheduleScopeType.everyday)
                            Text("Weekly").tag(ScheduleScopeType.weekday)
                            Text("One-Off").tag(ScheduleScopeType.oneOff)
                        }
                        .pickerStyle(.segmented)

                        if scopeType == .weekday {
                            weekdaySelector
                        } else if scopeType == .oneOff {
                            DatePicker(
                                "Date",
                                selection: $oneOffDate,
                                displayedComponents: .date
                            )
                            .padding(.horizontal, 4)
                        }
                    }

                    // Time range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            timeColumn(title: "Start", selection: $startMinutes, options: startOptions)
                            Text("–")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            timeColumn(title: "End", selection: $endMinutes, options: endOptions)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGray6))
            .navigationTitle(editingBlock == nil ? "New Block" : "Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .alert("Time Conflict", isPresented: $showOverlapAlert) {
                Button("Okay", role: .cancel) { }
            } message: {
                Text("This time overlaps an existing block in the same schedule. Items can't overlap — pick a different time.")
            }
            .onChange(of: startMinutes) { _, newStart in
                // Keep the end time after the start time.
                if endMinutes <= newStart {
                    endMinutes = min(newStart + 15, 24 * 60)
                }
            }
        }
    }

    // MARK: - Subviews

    private var weekdaySelector: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { weekday in
                let isSelected = selectedWeekdays.contains(weekday)
                Button(action: {
                    if isSelected {
                        selectedWeekdays.remove(weekday)
                    } else {
                        selectedWeekdays.insert(weekday)
                    }
                }) {
                    Text(weekdaySymbols[weekday - 1])
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(isSelected ? Color.orange : Color(.systemBackground))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func timeColumn(title: String, selection: Binding<Int>, options: [Int]) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { minutes in
                    Text(formatMinutesAsTime(minutes)).tag(minutes)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 130, height: 120)
            .clipped()
        }
    }

    // MARK: - Time slot options

    // Start can be any slot except the very end of the day.
    private var startOptions: [Int] {
        dailyTimeSlots.filter { $0 < 24 * 60 }
    }

    // End must be strictly after the chosen start time.
    private var endOptions: [Int] {
        dailyTimeSlots.filter { $0 > startMinutes }
    }

    // MARK: - Save

    private func save() {
        guard isValid else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let calendar = Calendar.current

        var candidate = editingBlock ?? ScheduleBlock(
            title: trimmedTitle,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            scopeType: scopeType
        )
        candidate.title = trimmedTitle
        candidate.startMinutes = startMinutes
        candidate.endMinutes = endMinutes
        candidate.scopeType = scopeType

        switch scopeType {
        case .everyday:
            candidate.weekdays = nil
            candidate.date = nil
        case .weekday:
            candidate.weekdays = selectedWeekdays.sorted()
            candidate.date = nil
        case .oneOff:
            candidate.weekdays = nil
            candidate.date = calendar.startOfDay(for: oneOffDate)
        }

        // Overlap check within the candidate's own scope grouping.
        let scopesToCheck: [ResolvedScope]
        switch scopeType {
        case .everyday:
            scopesToCheck = [.everyday]
        case .weekday:
            scopesToCheck = selectedWeekdays.map { .weekday($0) }
        case .oneOff:
            scopesToCheck = [.oneOff(calendar.startOfDay(for: oneOffDate))]
        }

        let overlaps = scopesToCheck.contains { scope in
            scheduleManager.wouldOverlap(candidate, in: scope, excluding: candidate.id)
        }

        if overlaps {
            showOverlapAlert = true
            return
        }

        if editingBlock == nil {
            scheduleManager.addBlock(candidate)
        } else {
            scheduleManager.updateBlock(candidate)
        }

        isPresented = false
    }
}
