//
//  SchedulePersistenceManager.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import Foundation
import Combine

class SchedulePersistenceManager: ObservableObject {
    static let shared = SchedulePersistenceManager()

    @Published var scheduleCollection = ScheduleCollection()

    private let fileName = "schedule.json"

    private init() {
        loadBlocks()
    }

    // Get the file URL for saving the schedule.
    private func getFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }

    // Save the schedule to local storage.
    func saveBlocks() {
        do {
            let data = try JSONEncoder().encode(scheduleCollection)
            try data.write(to: getFileURL())
            print("Schedule saved successfully to: \(getFileURL().path)")
        } catch {
            print("Failed to save schedule: \(error.localizedDescription)")
        }
    }

    // Load the schedule from local storage.
    func loadBlocks() {
        let fileURL = getFileURL()

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Schedule file doesn't exist yet")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            scheduleCollection = try JSONDecoder().decode(ScheduleCollection.self, from: data)
            print("Schedule loaded successfully")
        } catch {
            print("Failed to load schedule: \(error.localizedDescription)")
            scheduleCollection = ScheduleCollection()
        }
    }

    // MARK: - CRUD

    func addBlock(_ block: ScheduleBlock) {
        scheduleCollection.blocks.append(block)
        saveBlocks()
    }

    func updateBlock(_ updatedBlock: ScheduleBlock) {
        if let index = scheduleCollection.blocks.firstIndex(where: { $0.id == updatedBlock.id }) {
            scheduleCollection.blocks[index] = updatedBlock
            saveBlocks()
        }
    }

    // Delete a block and cascade-delete any tasks linked to it.
    func deleteBlock(withId id: UUID) {
        scheduleCollection.blocks.removeAll { $0.id == id }
        TaskPersistenceManager.shared.deleteTasks(forBlock: id)
        saveBlocks()
    }

    // MARK: - Queries

    // All scopes available to view on a given date, ordered most-specific first
    // (one-off date -> weekday-custom -> general). "General" is always available.
    func availableScopes(on date: Date) -> [ResolvedScope] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        var scopes: [ResolvedScope] = []

        // One-off scope for this exact date, if any block targets it.
        let hasOneOff = scheduleCollection.blocks.contains { block in
            block.scopeType == .oneOff && (block.date.map { calendar.isDate($0, inSameDayAs: date) } ?? false)
        }
        if hasOneOff {
            scopes.append(.oneOff(calendar.startOfDay(for: date)))
        }

        // Weekday scope for this weekday, if any block targets it.
        let hasWeekday = scheduleCollection.blocks.contains { block in
            block.scopeType == .weekday && (block.weekdays?.contains(weekday) ?? false)
        }
        if hasWeekday {
            scopes.append(.weekday(weekday))
        }

        // General scope is always available.
        scopes.append(.everyday)

        return scopes
    }

    // The scope to show by default for a given date (most specific available).
    func defaultScope(on date: Date) -> ResolvedScope {
        availableScopes(on: date).first ?? .everyday
    }

    // Blocks belonging to a resolved scope, sorted by start time.
    func blocks(for scope: ResolvedScope) -> [ScheduleBlock] {
        scheduleCollection.blocks
            .filter { $0.belongs(to: scope) }
            .sorted { $0.startMinutes < $1.startMinutes }
    }

    // Whether a candidate block would overlap any existing block in the same scope grouping.
    // When editing, pass the block's own id to exclude it from the check.
    func wouldOverlap(_ candidate: ScheduleBlock, in scope: ResolvedScope, excluding excludedID: UUID? = nil) -> Bool {
        blocks(for: scope).contains { existing in
            existing.id != excludedID && existing.overlaps(candidate)
        }
    }
}
