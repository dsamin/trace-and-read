//
//  LetterMastery.swift
//  Chassis › ReviewService
//
//  SwiftData record of how well a single letter is known. Mastery is the
//  signal that tightens stroke-validation tolerance (handled in the app's
//  validator) and that the spaced-repetition scheduler uses to pick what to
//  review next.
//
//  CHASSIS RULE: Foundation / SwiftData only.
//

import Foundation
import SwiftData

@Model
public final class LetterMastery {
    /// The character, e.g. "a". Unique so there is one row per letter.
    @Attribute(.unique) public var letter: String

    /// Total free-write attempts seen.
    public var attempts: Int
    /// Successful unscaffolded free-writes.
    public var successes: Int
    /// Consecutive successes — drives the spaced-repetition interval.
    public var streak: Int
    /// When this letter was last practiced.
    public var lastReviewed: Date
    /// When it next becomes due for review.
    public var nextDue: Date

    public init(letter: String,
                attempts: Int = 0,
                successes: Int = 0,
                streak: Int = 0,
                lastReviewed: Date = .now,
                nextDue: Date = .now) {
        self.letter = letter
        self.attempts = attempts
        self.successes = successes
        self.streak = streak
        self.lastReviewed = lastReviewed
        self.nextDue = nextDue
    }

    /// Mastery as 0...1: blends success rate with how deep the streak is, so a
    /// few good reps in a row meaningfully tighten tolerance.
    public var fraction: Double {
        guard attempts > 0 else { return 0 }
        let rate = Double(successes) / Double(attempts)
        let streakBoost = min(1.0, Double(streak) / 5.0)   // capped at 5 in a row
        return min(1.0, 0.6 * rate + 0.4 * streakBoost)
    }
}
