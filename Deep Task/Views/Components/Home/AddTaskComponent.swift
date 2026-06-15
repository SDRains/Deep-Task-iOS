//
//  AddTaskComponent.swift
//  Deep Task
//
//  Created by Stephen Rains on 8/28/25.
//

import SwiftUI

struct AddTaskView: View {
    @Binding var isPresented: Bool
    // When set, the created task is linked to a schedule block instead of the Home list.
    var scheduleBlockID: UUID? = nil
    @State private var title = ""
    @State private var tasks: [String] = [""]
    @State private var hours = 0
    @State private var minutes = 0
    @FocusState private var focusedTaskIndex: Int?

    // Add reference to persistence manager
    @ObservedObject private var persistenceManager = TaskPersistenceManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                let sectionSpace: CGFloat = 0
                
                VStack(alignment: .leading, spacing: 28) {
                    // Short intro explaining the philosophy of the form.
                    Text("Turn a big goal into focused, bite-sized progress.")
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // MARK: Goal
                    section {
                        SectionHeader(icon: "target", title: "Goal", tint: .orange)

                        explainer("Name the one outcome you're working toward. A clear goal gives your session direction and a finish line to aim for.")

                        FloatingLabelTextField(placeholder: "e.g. Finish the Capex report", text: $title)
                    }
                    
                    Spacer(minLength: sectionSpace)

                    // MARK: Tasks
                    section {
                        HStack(alignment: .center) {
                            SectionHeader(icon: "checklist", title: "Tasks", tint: .blue)

                            Spacer()

                            Button(action: {
                                tasks.append("")
                                focusedTaskIndex = tasks.count - 1
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                            }
                        }

                        explainer("Break that goal into small, concrete steps. Checking them off one at a time builds momentum and turns an overwhelming task into a series of manageable wins.")

                        VStack(spacing: 12) {
                            ForEach(tasks.indices, id: \.self) { index in
                                HStack(alignment: .center, spacing: 8) {
                                    FloatingLabelTextField(
                                        placeholder: "Step \(index + 1)",
                                        text: $tasks[index]
                                    )
                                    .focused($focusedTaskIndex, equals: index)

                                    if tasks.count > 1 {
                                        Button(action: {
                                            tasks.remove(at: index)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title3)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: sectionSpace)

                    // MARK: Duration
                    section {
                        SectionHeader(icon: "timer", title: "Focus Duration", tint: .red)

                        explainer("Give yourself a focused time box. Working against a gentle countdown encourages deep, distraction-free work and helps you fully commit to the task.")

                        durationPicker
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("New Task")
            .background(Color(.systemGray6))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || tasks.allSatisfy { $0.isEmpty })
                }
            }
            // Tap gesture to dismiss keyboard
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                AnalyticsService.shared.trackScreen(.addTask, properties: [
                    "isScheduleBlockTask": scheduleBlockID != nil
                ])
            }
        }
    }

    // MARK: - Section building blocks

    @ViewBuilder
    private func section<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(.horizontal, 20)
    }

    private func explainer(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var durationPicker: some View {
        HStack(spacing: 20) {
            // Hours Picker
            VStack {
                Text("Hours")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Hours", selection: $hours) {
                    ForEach(0...3, id: \.self) { hour in
                        Text("\(hour)")
                            .tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 120, height: 100)
                .clipped()
            }

            Text(":")
                .font(.title2)
                .foregroundColor(.secondary)

            // Minutes Picker
            VStack {
                Text("Minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Minutes", selection: $minutes) {
                    // If 3 hours selected, limit minutes to 0
                    if hours == 3 {
                        Text("00").tag(0)
                    } else {
                        ForEach(Array(stride(from: 0, to: 60, by: 1)), id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .tag(minute)
                        }
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 120, height: 100)
                .clipped()
                .onChange(of: hours) { _, newValue in
                    // Reset minutes to 0 if 3 hours is selected
                    if newValue == 3 {
                        minutes = 0
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .contentCard(backgroundColor: Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? .systemGray5 : .systemBackground
        }))
    }

    // Save task function
    private func saveTask() {
        // Filter out empty tasks
        let validTasks = tasks.filter { !$0.isEmpty }

        guard !title.isEmpty && !validTasks.isEmpty else {
            return
        }

        // Convert duration to minutes
        let durationInMinutes = (hours * 60) + minutes

        // Create TaskItem objects from the valid task strings
        let taskItems = validTasks.map { taskTitle in
            TaskItem(title: taskTitle, completed: false)
        }

        // Create the MainTask object
        let newMainTask = MainTask(
            title: title,
            tasks: taskItems,
            duration: durationInMinutes,
            scheduleBlockID: scheduleBlockID
        )

        // Save using persistence manager
        persistenceManager.addTask(newMainTask)

        AnalyticsService.shared.track("Task Created", properties: [
            "subtaskCount": validTasks.count,
            "taskDuration": durationInMinutes,
            "isScheduleBlockTask": scheduleBlockID != nil
        ])

        // Close the sheet
        isPresented = false
    }

    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// A small section header: tinted icon in a circle + a rounded bold title.
struct SectionHeader: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tint.opacity(0.15)))

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

// Custom Floating Label TextField
struct FloatingLabelTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder/Label - now disappears when focused or has text
            if !isFocused && text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .transition(.opacity)
            }

            // TextField
            TextField("", text: $text)
                .focused($isFocused)
                .font(.system(size: 16))
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? AppTheme.accent : Color.clear, lineWidth: 2)
                )
        }
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .animation(.easeOut(duration: 0.2), value: text.isEmpty)
        .background(Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? .systemGray5 : .systemBackground
        }))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: AppTheme.cardShadow(), radius: 4, x: 0, y: 2)
    }
}

// Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var showAddTask = true

        var body: some View {
            AddTaskView(isPresented: $showAddTask)
        }
    }

    return PreviewWrapper()
}
