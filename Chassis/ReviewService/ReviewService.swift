//
//  ReviewService.swift
//  Chassis › ReviewService
//
//  The small cross-app "what needs review" service. Reads and writes
//  letter-formation mastery, and exposes a 0...1 mastery fraction that the
//  stroke validator turns into a tolerance. Spaced-repetition intervals grow
//  with the success streak.
//
//  CHASSIS RULE: Foundation / SwiftData only. No app-specific imports.
//

import Foundation
import SwiftData
import Observation   // @Observable / @ObservationIgnored without pulling in SwiftUI

@Observable
public final class ReviewService {

    @ObservationIgnored private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Expanding review intervals (in hours) indexed by success streak.
    /// Gentle and forgiving — this is a 4-year-old, not a flashcard grind.
    private static let intervalHours: [Double] = [0, 4, 24, 72, 168]

    // MARK: Reads

    /// Fetch (or lazily create) the mastery row for a letter.
    public func mastery(for letter: Character) -> LetterMastery {
        let key = String(letter).lowercased()
        let descriptor = FetchDescriptor<LetterMastery>(
            predicate: #Predicate { $0.letter == key }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let fresh = LetterMastery(letter: key)
        context.insert(fresh)
        return fresh
    }

    /// Mastery as 0...1 — the input the validator maps to a tolerance.
    public func masteryFraction(for letter: Character) -> Double {
        mastery(for: letter).fraction
    }

    /// Letters currently due for review, soonest first.
    public func dueLetters(asOf now: Date = .now) -> [LetterMastery] {
        let descriptor = FetchDescriptor<LetterMastery>(
            predicate: #Predicate { $0.nextDue <= now },
            sortBy: [SortDescriptor(\.nextDue)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: Writes

    /// Record the result of one unscaffolded free-write and reschedule.
    public func record(letter: Character, success: Bool, at now: Date = .now) {
        let row = mastery(for: letter)
        row.attempts += 1
        if success {
            row.successes += 1
            row.streak += 1
        } else {
            row.streak = 0
        }
        row.lastReviewed = now

        let idx = min(row.streak, Self.intervalHours.count - 1)
        let hours = Self.intervalHours[idx]
        row.nextDue = now.addingTimeInterval(hours * 3600)

        try? context.save()
    }
}
